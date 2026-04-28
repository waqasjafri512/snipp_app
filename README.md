# ⚡ Snipp - Premium Social Challenge & Calling Platform

**Snipp** is a state-of-the-art social media application that redefines interaction through "Dares," "Challenges," and seamless real-time connectivity. Built with a "Mobile First" philosophy, Snipp combines a high-performance backend with a stunning, micro-animated Flutter UI.

---

## ✨ Key Features

### 🏆 Dares & Challenges
*   **Dynamic Social Feed**: Experience a premium, scrollable feed of the latest dares and completions.
*   **Create & Accept**: Challenge your friends or the community. Upload photo/video evidence to prove your victory.
*   **Staggered Animations**: Enjoy a fluid UI experience with custom-built staggered list animations.

### 📞 Real-time Audio & Video Calling
*   **1-on-1 Premium Calling**: Crystal-clear voice and video calls powered by **Agora RTC**.
*   **Global Call Signaling**: Receive and answer calls from any screen in the app with our custom `CallProvider` architecture.
*   **Handshake System**: Robust Socket.io signaling ensures instant connection and reliable call termination.

### 💬 Hyper-Fast Messaging
*   **Real-time Chat**: High-performance messaging with gradient bubbles, read receipts, and typing indicators.
*   **Group Conversations**: Create and manage groups with specialized notifications and real-time synchronization.

### 📸 Moments & Stories
*   **24-Hour Stories**: Share disappearing moments. Features a professional story viewer with progress bars and reactions.
*   **Live Streaming**: Go live to your followers with low-latency streaming and real-time viewer interaction.

### 🎨 Premium Design System
*   **Glassmorphism & Gradients**: A modern aesthetic featuring HSL-curated color palettes and smooth linear transitions.
*   **Theme Center**: Switch between "Midnight Dark" and "Premium Light" modes instantly.
*   **Typography**: Powered by *Bricolage Grotesque* and *Plus Jakarta Sans* for a professional feel.

---

## 🛠 Tech Stack

### Mobile (Flutter)
- **State Management**: Provider & MultiProvider
- **Real-time**: Socket.io Client
- **RTC**: Agora RTC Engine
- **Auth & Notifications**: Firebase Auth & FCM
- **Architecture**: Clean UI/Provider separation

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: PostgreSQL with **Resilient Query Logic** (Auto-retries for connection drops)
- **Real-time Server**: Socket.io
- **Cloud Integration**: Firebase Admin SDK & Cloudinary

---

## 🚀 Installation & Setup

### 1. Prerequisites
- Flutter SDK (v3.10.0+)
- Node.js (v16.0.0+)
- PostgreSQL Database
- Firebase Project (with `google-services.json`)

### 2. Mobile App Setup
```bash
cd mobile_app
flutter pub get
# Configure Firebase
flutterfire configure
# Run the app
flutter run
```

### 3. Backend Setup
```bash
cd backend
npm install
# Configure your .env file
cp .env.example .env
# Start the server
npm run dev
```

---

## 📂 Project Highlights

- **Resilient DB**: Custom `queryResilient` wrapper to handle transient database connection terminations.
- **Smart Navigation**: System back-button interception to keep users within the primary app flow.
- **Push Architecture**: Integrated Firebase Cloud Messaging (FCM) for calls, messages, and social alerts.

---

Designed and developed with ❤️ by the **Snipp Team**.
