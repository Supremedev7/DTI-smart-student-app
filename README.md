# 🎓 Smart Student Assistant

**Smart Student Assistant** is an all-in-one AI-powered study companion built with Flutter. It helps students transform dense textbooks, handwritten notes, and scanned documents into manageable study materials like summaries, flashcards, and quizzes.



---

## 🚀 Features

### 🧠 Hybrid AI Engine
The app features a unique **AI Router** that automatically switches between:
* **Cloud Mode:** Uses the **Groq Llama 3 API** for high-reasoning summaries and complex quiz generation when online.
* **Offline Mode:** Uses a custom-built **On-Device NLP algorithm** to extract key sentences and generate study aids without an internet connection.

### 📸 Multi-Modal Input (OCR + PDF)
* **Digital PDFs:** Extract text from textbooks and research papers.
* **OCR Scanning:** Use the "Scan" feature to turn photos of handwritten lecture notes into digital text for analysis.

### 📚 Study Tools
* **Summarizer:** Condenses long chapters into "Key Takeaways" and "Next Steps."
* **Active Recall Flashcards:** Tinder-style swiping interface to master concepts.
* **Dynamic Quizzes:** AI-generated multiple-choice questions to test your knowledge retention.

### 🌍 Localization & Translation
Fully localized in 4 languages:
* 🇬🇧 **English** | 🇮🇳 **Hindi (हिंदी)** | 🇮🇳 **Telugu (తెలుగు)** | 🇮🇳 **Tamil (தமிழ்)**
* Includes **On-Device Translation** using Google ML Kit so you can study in your native language offline.

### 🎮 Gamification
* **XP System:** Earn experience points for every summary generated or quiz completed.
* **Streaks:** Keep your daily study habit alive with a visual streak tracker.
* **Leveling:** Progress through levels as you master your subjects.

---

## 🛠️ Tech Stack

| Category | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) |
| **Database** | [Hive](https://pub.dev/packages/hive) (Local NoSQL) |
| **Cloud AI** | [Groq API](https://groq.com/) (Llama-3.3-70b-versatile) |
| **Machine Learning** | Google ML Kit (Text Recognition & Translation) |
| **State Management** | ValueListenableBuilder (Reactive UI) |
| **Theme** | Adaptive Light & Dark Mode |

---

## 📦 Installation & Setup

### 1. Prerequisites
* Flutter SDK (3.19.0 or higher recommended)
* A Groq API Key (Get one free at [console.groq.com](https://console.groq.com/))

### 2. Clone the Repository
```bash
git clone [https://github.com/yourusername/smart-student-assistant.git](https://github.com/yourusername/smart-student-assistant.git)
cd smart-student-assistant
