import 'dart:math';

class OfflineNLPService {
  
  // A basic list of English filler words to ignore when finding important concepts
  static final Set<String> _stopWords = {
    "the", "a", "an", "and", "or", "but", "is", "are", "was", "were", "in", 
    "on", "at", "to", "for", "of", "with", "by", "as", "it", "this", "that", 
    "these", "those", "then", "than", "so", "be", "has", "had", "have", "will", 
    "would", "can", "could", "should", "from", "which", "who", "whom"
  };

  /// Helper to clean and split text into sentences
  static List<String> _getSentences(String text) {
    return text.replaceAll(RegExp(r'\n+'), ' ')
               .split(RegExp(r'(?<=[.!?])\s+'))
               .map((s) => s.trim())
               .where((s) => s.length > 20) // Ignore super short fragments like "Yes."
               .toList();
  }

  /// 1. SMART OFFLINE SUMMARIZER (Term Frequency Algorithm)
  static String summarize(String text) {
    List<String> sentences = _getSentences(text);
    if (sentences.isEmpty) return "Not enough text to summarize.";
    if (sentences.length <= 5) return sentences.map((s) => "• $s").join("\n\n");

    // Step 1: Calculate Word Frequencies across the entire document
    Map<String, int> wordFrequencies = {};
    Iterable<RegExpMatch> words = RegExp(r'\b[a-zA-Z]+\b').allMatches(text.toLowerCase());
    int maxFreq = 0;
    
    for (var match in words) {
      String word = match.group(0)!;
      if (!_stopWords.contains(word)) {
        wordFrequencies[word] = (wordFrequencies[word] ?? 0) + 1;
        if (wordFrequencies[word]! > maxFreq) {
          maxFreq = wordFrequencies[word]!;
        }
      }
    }

    // Step 2: Score each sentence based on its word values
    List<Map<String, dynamic>> scoredSentences = [];
    for (int i = 0; i < sentences.length; i++) {
      String sentence = sentences[i];
      double score = 0;
      Iterable<RegExpMatch> sentenceWords = RegExp(r'\b[a-zA-Z]+\b').allMatches(sentence.toLowerCase());
      
      for (var match in sentenceWords) {
        String word = match.group(0)!;
        if (wordFrequencies.containsKey(word)) {
          // Add the normalized word score
          score += wordFrequencies[word]! / maxFreq; 
        }
      }
      
      // Normalize by sentence length to prevent extremely long run-on sentences from always winning
      int wordCount = sentenceWords.length;
      if (wordCount > 0) score = score / wordCount;

      scoredSentences.add({"index": i, "sentence": sentence, "score": score});
    }

    // Step 3: Sort by score (Highest first) and pick the top 5
    scoredSentences.sort((a, b) => (b["score"] as double).compareTo(a["score"] as double));
    int limit = min(5, scoredSentences.length);
    List<Map<String, dynamic>> topSentences = scoredSentences.sublist(0, limit);

    // Step 4: Re-sort by original index so the summary reads logically from beginning to end
    topSentences.sort((a, b) => (a["index"] as int).compareTo(b["index"] as int));

    List<String> summaryPoints = topSentences.map((e) => "• ${e["sentence"]}").toList();
    return summaryPoints.join("\n\n");
  }

  /// 2. SMART OFFLINE FLASHCARDS
  static String generateFlashcards(String text) {
    List<String> sentences = _getSentences(text);
    if (sentences.isEmpty) return "Q: Not enough text.\nA: Try more text.";

    sentences.shuffle();
    int limit = min(10, sentences.length);
    String result = "";

    for (int i = 0; i < limit; i++) {
      String sentence = sentences[i];
      List<String> words = sentence.split(" ");
      
      // Find the longest/most complex word to act as the "Answer"
      words.sort((a, b) => b.length.compareTo(a.length));
      String keyword = words.first.replaceAll(RegExp(r'[^\w\s]+'), '');

      if (keyword.length > 4) {
        String question = sentence.replaceAll(keyword, "_____");
        result += "Q: $question\nA: $keyword\n\n";
      }
    }
    return result.trim();
  }

  /// 3. SMART OFFLINE QUIZZES
  static String generateQuiz(String text) {
    List<String> sentences = _getSentences(text);
    if (sentences.length < 4) return "Not enough text to build a quiz.";

    sentences.shuffle();
    int limit = min(5, sentences.length);
    String result = "";
    Random random = Random();

    // Gather a pool of hard distractors (words longer than 5 letters)
    List<String> allWords = text.replaceAll(RegExp(r'[^\w\s]+'), '').split(" ")
                                .where((w) => w.length > 5 && !_stopWords.contains(w.toLowerCase())).toList();

    for (int i = 0; i < limit; i++) {
      String sentence = sentences[i];
      List<String> words = sentence.split(" ");
      words.sort((a, b) => b.length.compareTo(a.length));
      
      String answer = words.first.replaceAll(RegExp(r'[^\w\s]+'), '');
      if(answer.length <= 3) continue; // Skip if the algorithm couldn't find a good keyword
      
      String question = sentence.replaceAll(answer, "_____") + "?";

      List<String> options = [answer];
      int attempts = 0;
      while (options.length < 4 && allWords.isNotEmpty && attempts < 20) {
        String distractor = allWords[random.nextInt(allWords.length)];
        if (!options.contains(distractor)) options.add(distractor);
        attempts++;
      }
      
      // Fallback if we couldn't find enough long words for distractors
      if (options.length < 4) {
        options.addAll(["All of the above", "None of the above", "Not mentioned"]);
        options = options.sublist(0, 4);
      }
      
      options.shuffle();

      int correctIndex = options.indexOf(answer);
      String correctLetter = ["A", "B", "C", "D"][correctIndex];

      result += "$question\n";
      result += "A) ${options[0]}\n";
      result += "B) ${options[1]}\n";
      result += "C) ${options[2]}\n";
      result += "D) ${options[3]}\n";
      result += "Answer: $correctLetter\n\n";
    }

    return result.trim();
  }
}