import 'dart:math';

class SmartOfflineNLPService {
  
  static final Set<String> _stopWords = {
    "a", "about", "above", "after", "again", "against", "all", "am", "an", "and", 
    "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", 
    "below", "between", "both", "but", "by", "can't", "cannot", "could", "couldn't", 
    "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", 
    "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", 
    "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers", 
    "herself", "him", "himself", "his", "how", "how's", "i", "i'd", "i'll", "i'm", 
    "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its", "itself", "let's", 
    "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", 
    "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", 
    "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", 
    "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", 
    "theirs", "them", "themselves", "then", "there", "there's", "these", "they", 
    "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", 
    "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", 
    "we're", "we've", "were", "weren't", "what", "what's", "when", "when's", "where", 
    "where's", "which", "while", "who", "who's", "whom", "why", "why's", "with", 
    "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've", 
    "your", "yours", "yourself", "yourselves", "will", "can", "may", "might"
  };

  static List<String> _getSentences(String text) {
    return text.replaceAll(RegExp(r'\n+'), ' ')
               .split(RegExp(r'(?<=[.!?])\s+'))
               .map((s) => s.trim())
               .where((s) => s.length > 30) // Only look at substantial sentences
               .toList();
  }

  // --- RAKE INFLUENCED KEY-PHRASE EXTRACTOR ---
  static Map<String, double> _extractKeyPhrases(String text) {
    String cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s\-]'), '');
    List<String> words = cleanText.split(RegExp(r'\s+'));
    
    Map<String, int> wordFrequency = {};
    Map<String, int> wordDegree = {};

    // 1. Build Phrases using stop words as delimiters
    List<String> currentPhrase = [];
    List<List<String>> phrases = [];

    for (String word in words) {
      if (_stopWords.contains(word)) {
        if (currentPhrase.isNotEmpty) {
          phrases.add(List.from(currentPhrase));
          currentPhrase.clear();
        }
      } else {
        currentPhrase.add(word);
      }
    }
    if (currentPhrase.isNotEmpty) phrases.add(currentPhrase);

    // 2. Calculate Degree and Frequency
    for (List<String> phrase in phrases) {
      int phraseLength = phrase.length;
      for (String word in phrase) {
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
        wordDegree[word] = (wordDegree[word] ?? 0) + phraseLength;
      }
    }

    // 3. Score Phrases (Degree / Frequency)
    Map<String, double> phraseScores = {};
    for (List<String> phrase in phrases) {
      double score = 0;
      for (String word in phrase) {
        score += (wordDegree[word]! / wordFrequency[word]!);
      }
      // Combine words back into string
      String fullPhrase = phrase.join(" ");
      if (fullPhrase.length > 4) { // Ignore tiny acronyms
        phraseScores[fullPhrase] = score;
      }
    }

    return phraseScores;
  }

  /// 1. INTELLIGENT SUMMARIZER (Up to 10 Points)
  static String summarize(String text) {
    List<String> sentences = _getSentences(text);
    if (sentences.isEmpty) return "Not enough text to summarize.";
    
    // If the text naturally has 10 or fewer sentences, just bullet point the whole thing
    if (sentences.length <= 10) return sentences.map((s) => "• $s").join("\n\n");

    Map<String, double> keyPhrases = _extractKeyPhrases(text);
    List<Map<String, dynamic>> scoredSentences = [];

    for (int i = 0; i < sentences.length; i++) {
      String sentence = sentences[i];
      double score = 0;
      String lowerSentence = sentence.toLowerCase();

      // Score sentence based on how many High-Value Phrases it contains
      keyPhrases.forEach((phrase, phraseScore) {
        if (lowerSentence.contains(phrase)) {
          score += phraseScore;
        }
      });

      scoredSentences.add({"index": i, "sentence": sentence, "score": score});
    }

    // Pick top 10 sentences instead of 5
    scoredSentences.sort((a, b) => (b["score"] as double).compareTo(a["score"] as double));
    int limit = min(10, scoredSentences.length); // <--- CHANGED TO 10
    List<Map<String, dynamic>> topSentences = scoredSentences.sublist(0, limit);
    
    // Sort chronologically so it still reads beautifully
    topSentences.sort((a, b) => (a["index"] as int).compareTo(b["index"] as int));

    return topSentences.map((e) => "• ${e["sentence"]}").join("\n\n");
  }

  /// 2. INTELLIGENT FLASHCARDS
  static String generateFlashcards(String text) {
    List<String> sentences = _getSentences(text);
    if (sentences.isEmpty) return "Q: Not enough text.\nA: Try more text.";

    Map<String, double> keyPhrases = _extractKeyPhrases(text);
    sentences.shuffle();
    int limit = min(10, sentences.length);
    String result = "";

    for (int i = 0; i < limit; i++) {
      String sentence = sentences[i];
      String lowerSentence = sentence.toLowerCase();
      
      String bestPhrase = "";
      double highestScore = -1;

      // Find the most intelligent phrase hidden inside this sentence
      keyPhrases.forEach((phrase, score) {
        if (lowerSentence.contains(phrase) && score > highestScore) {
          highestScore = score;
          bestPhrase = phrase;
        }
      });

      if (bestPhrase.isNotEmpty) {
        // Case-insensitive replace for the exact phrase
        String question = sentence.replaceAll(RegExp(r'\b' + bestPhrase + r'\b', caseSensitive: false), "_____");
        // Capitalize the answer for aesthetics
        String formattedAnswer = bestPhrase[0].toUpperCase() + bestPhrase.substring(1);
        result += "Q: $question\nA: $formattedAnswer\n\n";
      }
    }
    return result.trim();
  }

  /// 3. INTELLIGENT QUIZZES
  static String generateQuiz(String text) {
    List<String> sentences = _getSentences(text);
    if (sentences.length < 4) return "Not enough text to build a quiz.";

    Map<String, double> keyPhrases = _extractKeyPhrases(text);
    
    // --- THE FIX IS HERE ---
    // 1. Let Dart handle the MapEntry type correctly using 'var'
    var sortedEntries = keyPhrases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    // 2. Now extract just the Strings (the keys) into our distractor pool
    List<String> distractorPool = sortedEntries.take(30).map((e) => e.key).toList();
    // -----------------------

    sentences.shuffle();
    int limit = min(5, sentences.length);
    String result = "";
    Random random = Random();

    for (int i = 0; i < limit; i++) {
      String sentence = sentences[i];
      String lowerSentence = sentence.toLowerCase();
      
      String answer = "";
      double highestScore = -1;

      keyPhrases.forEach((phrase, score) {
        if (lowerSentence.contains(phrase) && score > highestScore) {
          highestScore = score;
          answer = phrase;
        }
      });

      if (answer.isEmpty) continue;

      String question = sentence.replaceAll(RegExp(r'\b' + answer + r'\b', caseSensitive: false), "_____") + "?";
      String formattedAnswer = answer[0].toUpperCase() + answer.substring(1);

      // Build options using the smart distractor pool
      List<String> options = [formattedAnswer];
      int attempts = 0;
      
      while (options.length < 4 && distractorPool.isNotEmpty && attempts < 30) {
        String distractor = distractorPool[random.nextInt(distractorPool.length)];
        String formattedDistractor = distractor[0].toUpperCase() + distractor.substring(1);
        
        if (!options.contains(formattedDistractor) && formattedDistractor.toLowerCase() != answer) {
          options.add(formattedDistractor);
        }
        attempts++;
      }
      
      // Fallback
      if (options.length < 4) {
        options.addAll(["All of the above", "None of the above", "Not specified"]);
        options = options.sublist(0, 4);
      }
      
      options.shuffle();

      int correctIndex = options.indexOf(formattedAnswer);
      String correctLetter = ["A", "B", "C", "D"][correctIndex];

      result += "$question\n";
      result += "A) ${options[0]}\n";
      result += "B) ${options[1]}\n";
      result += "C) ${options[2]}\n";
      result += "D) ${options[3]}\n";
      result += "Answer: $correctLetter\n\n";
    }

    return result.trim();
  }}