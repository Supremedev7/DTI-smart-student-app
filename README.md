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
git clone [https://github.com/Supremedev7/DTI-smart-student-app.git]
cd DTI-smart-student-app
```
3. Setup Environment Variables
Create a .env file in the root directory:

Code snippet
GROQ_API_KEY=your_groq_api_key_here
4. Install Dependencies
Bash
flutter pub get
5. Run the App
Bash
flutter run
📂 Project Structure
Plaintext
lib/
├── screens/      # All UI pages (Home, Profile, Settings, Study Tools)
├── services/     # AI Logic, Storage (Hive), and Translation services
├── utils/        # Localization strings and theme constants
├── widgets/      # Reusable components like Quiz cards and Flashcards
└── main.dart     # App entry point and global theme configuration
🛡️ Privacy & Security
Local-First: All study stats, names, and emails are stored locally on your device using Hive encryption.

Offline Support: Text analysis can be performed entirely on-device to ensure your notes never leave your phone unless Cloud AI is explicitly enabled.

📝 License
This project is licensed under the MIT License. Feel free to use it for your own educational projects!
