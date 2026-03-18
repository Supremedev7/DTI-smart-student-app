import 'dart:math';

/// A pure algorithmic, offline NLP engine optimized for Flutter.
/// Implements TF-IDF, Sparse TextRank, K-Means Clustering, and MMR.
class StatisticalNLPService {
  
  // --- 1. CORE CONFIGURATION & STOPWORDS ---
  static const Set<String> _stopwords = {
    'i','me','my','myself','we','our','ours','ourselves','you','your','yours','yourself',
    'yourselves','he','him','his','himself','she','her','hers','herself','it','its','itself',
    'they','them','their','theirs','themselves','what','which','who','whom','this','that',
    'these','those','am','is','are','was','were','be','been','being','have','has','had',
    'having','do','does','did','doing','a','an','the','and','but','if','or','because',
    'as','until','while','of','at','by','for','with','about','against','between','into',
    'through','during','before','after','above','below','to','from','up','down','in','out',
    'on','off','over','under','again','further','then','once','here','there','when','where',
    'why','how','all','any','both','each','few','more','most','other','some','such','no',
    'nor','not','only','own','same','so','than','too','very','s','t','can','will','just',
    'don','should','now','e','g','etc','al'
  };

  /// Main Entry Point: Parses the document once into a reusable memory state.
  static ProcessedDocument process(String text) {
    return ProcessedDocument(text);
  }

  // --- 2. TEXT CLEANING & NORMALIZATION ---

  static List<String> _segmentSentences(String text) {
    // 1. Protect abbreviations to prevent false splits
    String protected = text
        .replaceAll(RegExp(r'\b(Dr|Mr|Mrs|Ms|Prof|Sr|Jr)\.', caseSensitive: false), r'$1<DOT>')
        .replaceAll(RegExp(r'\b(e\.g|i\.e|etc|vs|al)\.', caseSensitive: false), r'$1<DOT>')
        .replaceAll(RegExp(r'\n+'), ' '); // Normalize newlines

    // 2. Split on actual sentence terminators
    List<String> raw = protected.split(RegExp(r'(?<=[.!?])\s+'));

    // 3. Clean up, revert abbreviations, and filter out noise/short sentences (< 25 chars)
    return raw.map((s) => s.replaceAll('<DOT>', '.').trim())
              .where((s) => s.length >= 25)
              .toList();
  }

  static List<String> _tokenize(String sentence) {
    String clean = sentence.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    return clean.split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopwords.contains(w))
        .map(_lightweightStemmer)
        .toList();
  }

  /// Extremely lightweight Porter-style suffix stripping
  static String _lightweightStemmer(String word) {
    if (word.endsWith('ies') && word.length > 4) return '${word.substring(0, word.length - 3)}y';
    if (word.endsWith('ing') && word.length > 4) return word.substring(0, word.length - 3);
    if (word.endsWith('ed') && word.length > 3) return word.substring(0, word.length - 2);
    if (word.endsWith('ly') && word.length > 3) return word.substring(0, word.length - 2);
    if (word.endsWith('s') && !word.endsWith('ss') && word.length > 3) return word.substring(0, word.length - 1);
    return word;
  }

  // --- 3. MATHEMATICAL FOUNDATIONS ---

  /// Computes Sparse Cosine Similarity (O(k) where k = unique words)
  static double _sparseCosine(Map<String, double> vecA, Map<String, double> vecB) {
    if (vecA.isEmpty || vecB.isEmpty) return 0.0;
    
    // Always iterate over the smaller map for performance
    if (vecA.length > vecB.length) {
      var temp = vecA; vecA = vecB; vecB = temp;
    }

    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (var entry in vecA.entries) {
      if (vecB.containsKey(entry.key)) dot += entry.value * vecB[entry.key]!;
      normA += entry.value * entry.value;
    }
    for (var val in vecB.values) {
      normB += val * val;
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }
}

/// Holds the pre-computed mathematical state of a document.
class ProcessedDocument {
  final List<String> sentences;
  final List<List<String>> tokenizedSentences;
  
  // Vector Caches
  late final Map<String, double> globalIdf;
  late final List<Map<String, double>> tfidfVectors;
  late final List<double> finalSentenceScores;
  late final List<String> topKeywords;

  ProcessedDocument(String text) 
      : sentences = StatisticalNLPService._segmentSentences(text),
        tokenizedSentences = [] {
    
    for (var s in sentences) {
      tokenizedSentences.add(StatisticalNLPService._tokenize(s));
    }
    
    _buildMathModels();
  }

  void _buildMathModels() {
    int total = sentences.length;
    if (total == 0) return;

    // 1. Calculate Smoothed IDF
    Map<String, int> df = {};
    for (var tokens in tokenizedSentences) {
      for (var word in tokens.toSet()) {
        df[word] = (df[word] ?? 0) + 1;
      }
    }
    
    globalIdf = {};
    df.forEach((word, count) {
      globalIdf[word] = log(total / (1 + count)) + 1.0; // Smoothed
    });

    // 2. Calculate Normalized TF-IDF Vectors
    tfidfVectors = [];
    for (var tokens in tokenizedSentences) {
      Map<String, double> vec = {};
      if (tokens.isNotEmpty) {
        Map<String, int> counts = {};
        for (var w in tokens) { counts[w] = (counts[w] ?? 0) + 1; }
        
        // Find max TF for normalization
        int maxTf = counts.values.reduce(max);
        counts.forEach((word, count) {
          vec[word] = (0.5 + 0.5 * (count / maxTf)) * (globalIdf[word] ?? 0.0);
        });
      }
      tfidfVectors.add(vec);
    }

    // 3. Extract Global Top Keywords (RAKE-style proxy)
    var sortedWords = globalIdf.keys.toList()
      ..sort((a, b) => (globalIdf[b]! * (df[b] ?? 1)).compareTo(globalIdf[a]! * (df[a] ?? 1)));
    topKeywords = sortedWords.take((sortedWords.length * 0.1).ceil()).toList(); // Top 10%

    // 4. Compute Sparse TextRank with Sliding Window (O(N*W) instead of O(N^2))
    List<Map<int, double>> graph = List.generate(total, (_) => {});
    const int windowSize = 50; // Only compare sentences within 50 slots of each other
    
    for (int i = 0; i < total; i++) {
      for (int j = i + 1; j < min(total, i + windowSize); j++) {
        double sim = StatisticalNLPService._sparseCosine(tfidfVectors[i], tfidfVectors[j]);
        if (sim > 0.1) { // Threshold filtering
          graph[i][j] = sim;
          graph[j][i] = sim;
        }
      }
    }

    // PageRank Iteration
    List<double> trScores = List.filled(total, 1.0);
    const double d = 0.85;
    for (int iter = 0; iter < 10; iter++) {
      List<double> nextScores = List.filled(total, 1 - d);
      for (int i = 0; i < total; i++) {
        double sum = 0.0;
        graph[i].forEach((neighborIdx, weight) {
          double outWeightSum = graph[neighborIdx].values.fold(0.0, (a, b) => a + b);
          if (outWeightSum > 0) sum += (weight / outWeightSum) * trScores[neighborIdx];
        });
        nextScores[i] += d * sum;
      }
      trScores = nextScores;
    }

    // 5. Final Composite Sentence Scoring
    finalSentenceScores = List.filled(total, 0.0);
    for (int i = 0; i < total; i++) {
      double tfidfSum = tfidfVectors[i].values.fold(0.0, (a, b) => a + b);
      double positionBoost = 1.0 - (i / total); // Early sentences matter more
      
      // Boost if sentence contains top keywords
      double keywordBoost = tokenizedSentences[i].where((w) => topKeywords.contains(w)).length * 0.5;

      finalSentenceScores[i] = (0.5 * trScores[i]) + (0.3 * tfidfSum) + (0.1 * positionBoost) + (0.1 * keywordBoost);
    }
  }

  // --- KNOWLEDGE ENGINE: HIERARCHICAL SUMMARIZATION ---

  String generateSummary({int maxSentences = 7}) {
    if (sentences.isEmpty) return "Document is empty.";
    if (sentences.length <= maxSentences) return sentences.map((s) => "• $s").join("\n\n");

    // Chunking for massive documents (Hierarchical Summarization)
    const int chunkSize = 40;
    List<int> candidateIndices = [];

    if (sentences.length > chunkSize) {
      for (int i = 0; i < sentences.length; i += chunkSize) {
        int end = min(sentences.length, i + chunkSize);
        candidateIndices.addAll(_runMMR(i, end, 3)); // 3 sentences per chunk
      }
    } else {
      candidateIndices = List.generate(sentences.length, (i) => i);
    }

    // Final MMR selection over the candidates
    List<int> finalSelection = _runMMRSelection(candidateIndices, maxSentences);
    finalSelection.sort(); // Chronological order

    return finalSelection.map((i) => "• ${sentences[i]}").join("\n\n");
  }

  List<int> _runMMR(int start, int end, int limit) {
    List<int> indices = List.generate(end - start, (i) => start + i);
    return _runMMRSelection(indices, limit);
  }

  List<int> _runMMRSelection(List<int> pool, int limit) {
    List<int> selected = [];
    List<int> remaining = List.from(pool);
    const double lambda = 0.65; // Aggressive redundancy penalty

    while (selected.length < limit && remaining.isNotEmpty) {
      double bestMMR = -double.infinity;
      int bestIdx = -1;

      for (int i in remaining) {
        double score = finalSentenceScores[i];
        double maxRedundancy = 0.0;
        
        for (int selIdx in selected) {
          double sim = StatisticalNLPService._sparseCosine(tfidfVectors[i], tfidfVectors[selIdx]);
          if (sim > maxRedundancy) maxRedundancy = sim;
        }

        double mmr = (lambda * score) - ((1 - lambda) * maxRedundancy);
        if (mmr > bestMMR) {
          bestMMR = mmr;
          bestIdx = i;
        }
      }

      if (bestIdx != -1) {
        selected.add(bestIdx);
        remaining.remove(bestIdx);
      }
    }
    return selected;
  }

  // --- KNOWLEDGE ENGINE: SEMANTIC SEARCH (ASK PDF) ---

  String askQuestion(String question) {
    if (sentences.isEmpty) return "Document is empty.";

    List<String> qTokens = StatisticalNLPService._tokenize(question);
    Map<String, double> qVec = {};
    for (var w in qTokens) {
      qVec[w] = (qVec[w] ?? 0) + 1.0;
      qVec[w] = qVec[w]! * (globalIdf[w] ?? 0.0);
    }

    // Find top 2 matches
    List<MapEntry<int, double>> matches = [];
    for (int i = 0; i < tfidfVectors.length; i++) {
      double sim = StatisticalNLPService._sparseCosine(qVec, tfidfVectors[i]);
      if (sim > 0.1) matches.add(MapEntry(i, sim));
    }

    if (matches.isEmpty) return "I couldn't find a direct answer to that in the notes.";

    matches.sort((a, b) => b.value.compareTo(a.value));
    int bestIdx = matches.first.key;

    // Provide context around the match
    int startIdx = max(0, bestIdx - 1);
    int endIdx = min(sentences.length - 1, bestIdx + 1);
    
    String context = sentences.sublist(startIdx, endIdx + 1).join(" ");
    return "Based on your document:\n\n\"...$context...\"";
  }

  // --- KNOWLEDGE ENGINE: FLASHCARDS ---

  String generateFlashcards({int limit = 10}) {
    if (sentences.length < limit) return "Not enough data.";

    List<int> bestIndices = List.generate(sentences.length, (i) => i);
    bestIndices.sort((a, b) => finalSentenceScores[b].compareTo(finalSentenceScores[a]));
    
    // Filter diverse sentences
    List<int> selected = _runMMRSelection(bestIndices.take(limit * 3).toList(), limit);

    String result = "";
    for (int i in selected) {
      Map<String, double> vec = tfidfVectors[i];
      if (vec.isEmpty) continue;

      // Find highest TF-IDF word to blank out
      String keyword = "";
      double maxVal = 0.0;
      vec.forEach((w, val) {
        if (val > maxVal && w.length > 4 && topKeywords.contains(w)) {
          maxVal = val;
          keyword = w;
        }
      });

      if (keyword.isNotEmpty) {
        String q = sentences[i].replaceAll(RegExp(r'\b' + keyword + r'[a-z]*\b', caseSensitive: false), "_____");
        result += "Q: $q\nA: ${keyword.toUpperCase()}\n\n";
      }
    }
    return result.trim();
  }

  // --- KNOWLEDGE ENGINE: QUIZZES ---

  String generateQuiz({int limit = 5}) {
    if (sentences.length < limit) return "Not enough data.";
    
    List<int> bestIndices = List.generate(sentences.length, (i) => i);
    bestIndices.sort((a, b) => finalSentenceScores[b].compareTo(finalSentenceScores[a]));
    List<int> selected = _runMMRSelection(bestIndices.take(limit * 2).toList(), limit);

    String result = "";
    var rand = Random();

    for (int i in selected) {
      String answer = "";
      double maxVal = 0.0;
      tfidfVectors[i].forEach((w, val) {
        if (val > maxVal && w.length > 4) { maxVal = val; answer = w; }
      });

      if (answer.isEmpty) continue;
      String q = "${sentences[i].replaceAll(RegExp(r'\b' + answer + r'[a-z]*\b', caseSensitive: false), "_____")}?";
      
      List<String> options = [answer.toUpperCase()];
      List<String> pool = List.from(topKeywords)..shuffle(rand);
      
      for (String distractor in pool) {
        if (options.length >= 4) break;
        if (distractor.toUpperCase() != answer.toUpperCase() && !options.contains(distractor.toUpperCase())) {
          options.add(distractor.toUpperCase());
        }
      }

      options.shuffle(rand);
      String correctLtr = ["A", "B", "C", "D"][options.indexOf(answer.toUpperCase())];

      result += "$q\nA) ${options[0]}\nB) ${options[1]}\nC) ${options[2]}\nD) ${options[3]}\nAnswer: $correctLtr\n\n";
    }
    return result.trim();
  }

  // --- KNOWLEDGE ENGINE: TOPIC CLUSTERING (K-MEANS) ---

  String extractTopics({int k = 3}) {
    if (tfidfVectors.length < k * 3) return "Document too small for clustering.";
    
    var rand = Random(42); // Deterministic
    List<Map<String, double>> centroids = List.generate(k, (i) => tfidfVectors[rand.nextInt(tfidfVectors.length)]);
    List<List<int>> clusters = List.generate(k, (_) => []);

    for (int iter = 0; iter < 5; iter++) {
      clusters = List.generate(k, (_) => []);
      for (int i = 0; i < tfidfVectors.length; i++) {
        int bestC = 0;
        double maxSim = -1.0;
        for (int c = 0; c < k; c++) {
          double sim = StatisticalNLPService._sparseCosine(tfidfVectors[i], centroids[c]);
          if (sim > maxSim) { maxSim = sim; bestC = c; }
        }
        clusters[bestC].add(i);
      }

      // Recompute centroids
      for (int c = 0; c < k; c++) {
        if (clusters[c].isEmpty) continue;
        Map<String, double> newC = {};
        for (int idx in clusters[c]) {
          tfidfVectors[idx].forEach((k, v) => newC[k] = (newC[k] ?? 0) + v);
        }
        newC.forEach((key, val) => newC[key] = val / clusters[c].length);
        centroids[c] = newC;
      }
    }

    String output = "Main Topics Detected:\n";
    for (int c = 0; c < k; c++) {
      if (centroids[c].isEmpty) continue;
      var sortedKeys = centroids[c].keys.toList()..sort((a, b) => centroids[c][b]!.compareTo(centroids[c][a]!));
      String topicWords = sortedKeys.take(3).map((s) => s.toUpperCase()).join(" / ");
      
      // Get the most representative sentence for this cluster
      int repIdx = clusters[c].reduce((a, b) => 
        StatisticalNLPService._sparseCosine(tfidfVectors[a], centroids[c]) > 
        StatisticalNLPService._sparseCosine(tfidfVectors[b], centroids[c]) ? a : b);
      
      output += "\nCluster ${c + 1}: $topicWords\nContext: ${sentences[repIdx]}\n";
    }
    return output;
  }
}