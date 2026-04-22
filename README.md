# ⚡ Snipp - Premium Social Challenge App

**Snipp** is a modern, high-performance social media application built with Flutter. It focuses on "Dares" and "Challenges," allowing users to interact through real-time chat, live streaming, and 24-hour stories.

## ✨ Features

*   **Social Feed**: A dynamic, premium feed of dares and completions.
*   **Challenges & Dares**: Create, accept, and complete challenges with photo/video evidence.
*   **Real-time Chat**: High-performance messaging with gradient bubbles and instant delivery.
*   **Live Streaming**: Low-latency video streaming powered by Agora.
*   **Stories**: 24-hour disappearing moments with professional viewing and management.
*   **Premium Design**: Custom-built UI using Google Fonts (Bricolage Grotesque & Plus Jakarta Sans), smooth gradients, and micro-animations.
*   **Secure Auth**: JWT-based authentication with a professional onboarding flow.

## 📸 UI Gallery

> [!TIP]
> This app uses a "Premium Light Mode" design system with vibrant gradients and soft shadows for a state-of-the-art feel.

## 🛠 Tech Stack

*   **Framework**: [Flutter](https://flutter.dev) (v3.10+)
*   **State Management**: Provider
*   **Networking**: Http & Socket.io Client
*   **Real-time**: Socket.io
*   **RTC**: Agora RTC Engine
*   **Storage**: Flutter Secure Storage
*   **Typography**: Google Fonts

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (v3.0.0 or higher)
*   Dart SDK (v3.0.0 or higher)
*   A running instance of the [Snipp Backend](https://github.com/your-username/snipp-backend)

### Installation

1.  **Clone the repository**:
    ```bash
    git clone <your-repo-url>
    cd dare-challenge/mobile_app
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Configure API URL**:
    Open `lib/core/constants/app_constants.dart` and ensure the `apiUrl` points to your backend:
    ```dart
    static const String apiUrl = 'https://your-backend-url.com/api';
    ```

4.  **Run the app**:
    ```bash
    # For Android
    flutter run

    # For iOS
    flutter run
    ```

## 📂 Project Structure

```text
lib/
├── core/           # Constants, Themes, Utilities
├── data/           # Models, Services, Repositories
├── presentation/   # Screens, Widgets, Providers (State)
└── main.dart       # Entry point
```

---

Designed and developed with ❤️ by the Snipp Team.
