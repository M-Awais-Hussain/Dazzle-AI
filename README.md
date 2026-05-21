# ayyy - AI Furniture & Room Designer Marketplace

A modern, comprehensive Flutter application that acts as a marketplace connecting Users, Interior Designers, and Marketplace Owners. The platform empowers users to redesign their spaces using advanced AI, consult with professional designers, and purchase furniture directly.

## Project Overview

This project is a full-featured marketplace that redefines how users shop for and visualize furniture in their own environments. It seamlessly blends e-commerce, real-time communication, and state-of-the-art AI.

### Key Roles
- **Users**: Can upload room photos, use AI to visualize new furniture layouts, chat with designers for advice, and place orders.
- **Designers**: Can manage their portfolio, receive and respond to design requests, chat with clients in real-time, and track their earnings via custom dashboards.
- **Marketplace Owners**: Can oversee the platform, manage inventory, and handle order fulfillment.

## Technologies & Libraries Used

The application is built on a modern and robust tech stack:

- **Frontend Framework**: [Flutter](https://flutter.dev/) (SDK ^3.11.5) for cross-platform UI.
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) for scalable and reactive state.
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing and deep linking.
- **Backend & Database**: [Supabase](https://supabase.com/) (`supabase_flutter`) for authentication, real-time database syncing, and cloud storage.
- **Networking**: [Dio](https://pub.dev/packages/dio) with `pretty_dio_logger` for structured HTTP requests to external APIs.
- **Data Models**: [Freezed](https://pub.dev/packages/freezed) & `json_serializable` for immutable state and safe JSON serialization.
- **Local Storage**: `flutter_secure_storage` and `shared_preferences` for securely persisting local data and sessions.
- **UI & Visualization**: `fl_chart` for rendering earnings and analytics dashboards.

## How the AI & API Integrations Work

The core magic of the application is handled through coordinated API services that automate the background removal and spatial analysis:

1. **Image Selection & Background Removal (Remove.bg API)**
   - When a user wants to test a product in their room, the product image is sent to the **Remove.bg API** via our network layer.
   - The API processes the image, strips away the original background, and returns a clean, transparent PNG of the furniture item.
   - The application caches these transparent images to optimize performance and reduce API calls.

2. **AI Spatial & Layout Analysis (Google Gemini API)**
   - The transparent furniture image and the user's room photo are packaged alongside contextual metadata (such as product dimensions and room type).
   - This data is securely sent to the **Google Gemini 2.5 Flash API**.
   - Gemini acts as an AI interior designer: it analyzes the geometry, lighting, and perspective of the room to determine the most natural and aesthetically pleasing location for the furniture.
   - The AI returns precise normalized coordinates (bounding boxes).

3. **Rendering & Compositing**
   - The Flutter frontend receives the coordinates and utilizes the native `dart:ui` Canvas.
   - It composites the transparent furniture image perfectly over the original room photo, creating a realistic and immediate preview for the user.

## How to Run This Project

Follow these steps to set up and run the project locally.

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.11.5 or compatible)
- A Supabase Project (with the provided SQL migrations applied)
- Google Gemini API Key
- Remove.bg API Key

### Setup Instructions

1. **Clone the repository** and navigate to the project directory:
   ```bash
   cd Dazzle-AI
   ```

2. **Install dependencies**:
   Fetch all required Flutter packages:
   ```bash
   flutter pub get
   ```

3. **Generate Code (Freezed & JSON Serializable)**:
   Since the project uses code generation for models, run the build runner to generate the necessary `.g.dart` and `.freezed.dart` files:
   ```bash
   dart run build_runner build -d
   ```

4. **Configure Environment Variables**:
   Create a `.env` file in the root of the project (at the same level as `pubspec.yaml`) and add your API keys:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GEMINI_API_KEY=your_gemini_api_key
   REMOVE_BG_API_KEY=your_remove_bg_api_key
   ```
   *(Ensure your `.env` file is declared in your `pubspec.yaml` assets so Flutter can read it).*

5. **Run the App**:
   Launch the app on your connected device or emulator:
   ```bash
   flutter run
   ```
