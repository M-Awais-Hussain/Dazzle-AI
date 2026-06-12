# Dazzle-AI - AI Furniture & Room Designer Collaboration Platform

Dazzle-AI is a modern, comprehensive Flutter application that acts as a collaborative spatial design platform connecting **Users**, **Interior Designers**, and **Marketplace Owners**. 

Instead of a traditional shopping cart experience, Dazzle-AI focuses on interactive, real-time spatial design. It empowers users to visualize furniture in their own rooms using an advanced 2.5D perspective canvas, configure dynamic product variants, hire professional designers, and collaborate with them live on a synchronized canvas.

---

## Project Overview

Dazzle-AI redefines how spaces are visualized, designed, and customized. It bridges the gap between client imagination and professional design expertise through real-time communication, custom spatial canvas controls, and smart image processing.

### Key Roles
- **Users**: Can upload room photos, utilize the interactive 2.5D canvas to place and adjust furniture, swap product colors or layout configurations, hire professional designers, and participate in live real-time design collaborations.
- **Designers**: Can manage their design portfolios, accept hire requests, collaborate with clients on a live canvas in real-time, generate final composite designs, and automatically showcase completed projects.
- **Marketplace Owners**: Can oversee the furniture catalog, configure rich product variants (colors, layouts, and corresponding assets), and analyze platform engagement via custom analytics dashboards.

---

## Key Features

### 1. Interactive 2.5D Perspective Canvas
Dazzle-AI features a sophisticated custom-drawn canvas (`PerspectiveProductCanvas`) to position transparent cutouts of furniture inside room photos:
- **Spatial Positioning & Transforms**: Supports multi-touch translation, scaling, and rotation.
- **2.5D Perspective Tilts**: Allows adjustment of X-axis and Y-axis tilt angles via a Matrix4 transform with perspective distortion (`setEntry(3, 2, 0.001)`).
- **Depth-Based Scaling**: Automatically adjusts the scale of the furniture based on its vertical position (`dy`) on the canvas—simulating realistic depth and distance as objects move higher (farther) or lower (closer).
- **Floor Shadow Simulation**: Renders adjustable floor shadows (`CanvasShadowPainter`) that dynamically follow the furniture's translation, rotation, scale, and tilts.

### 2. Live Real-Time Collaboration
Designers and clients can work together on the exact same project canvas in real-time:
- **Low-Latency Sync**: Canvas transformations (coordinates, rotation, scale, tilts, and variant selections) are broadcasted between the user and designer via **Supabase Broadcast Channels (WebSockets)**, throttled to 15 FPS (66ms) for smooth synchronization without lag.
- **Persistent Synchronization**: Changes are periodically saved to the database using a 500ms debounced database write stream, minimizing server load while ensuring persistence.
- **Final Composition & Delivery**: Once the layout is finalized, the designer composites the elements, uploads the final high-resolution render to Supabase Storage, delivers it in chat, and can automatically list it in their portfolio.

### 3. Dynamic Product Variants
Products are not static images. They support multiple configurable dimensions, materials, and colors:
- **Color Variants**: Configured with hexadecimal codes and names. Swapping colors updates the active canvas asset in real-time.
- **Layout Variants**: Configured for different orientations (e.g., horizontal vs. vertical layouts).
- **Background Removal Integration**: Swapping variants retrieves pre-processed transparent images or automatically removes the background of the raw asset on-the-fly using the Remove.bg API, uploading the result for future users.

---

## Technologies & Libraries Used

The application is built on a modern and robust Flutter stack:

- **Frontend Framework**: [Flutter](https://flutter.dev/) (SDK ^3.11.5) for cross-platform UI.
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) for scalable and reactive state.
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing, access guards, and role-based redirect logic.
- **Backend & Database**: [Supabase](https://supabase.com/) (`supabase_flutter`) for authentication, database access, real-time database streams, websocket broadcasting, and storage.
- **Networking**: [Dio](https://pub.dev/packages/dio) with `pretty_dio_logger` for structured HTTP requests to external APIs.
- **Data Models**: [Freezed](https://pub.dev/packages/freezed) & `json_serializable` for immutable state and safe JSON serialization.
- **Local Storage**: `flutter_secure_storage` and `shared_preferences` for securely persisting local data and sessions.
- **UI & Visualization**: `fl_chart` for rendering earnings and analytics dashboards.
- **Utilities**: `image` for programmatic image manipulation and compositing, and `url_launcher` for external links.

---

## How the AI & API Integrations Work

The core magic of the application is handled through coordinated API services:

1. **Image Selection & Background Removal (Remove.bg API)**
   - When a product or variant is loaded into the canvas, the raw image is processed via the **Remove.bg API** to isolate the furniture item.
   - The application uploads and caches these transparent cutout images to Supabase Storage to optimize load times and minimize API usage.

2. **AI Spatial & Layout Analysis (Google Gemini API)**
   - To offer an automated alternative, the transparent furniture cutout and the user's room photo are packaged alongside metadata (such as product dimensions and room type).
   - This data is sent to the **Google Gemini 2.5 Flash API**.
   - Gemini acts as an AI interior designer, evaluating the geometry, lighting, and perspective of the room to return precise normalized coordinates (bounding boxes) for the best placement.

3. **Rendering, Compositing & Live Synchronisation**
   - The Flutter frontend composites the assets perfectly on the 2.5D canvas using a custom Matrix4 transform matrix.
   - During collaboration sessions, updates to these transforms are broadcasted across WebSockets in real-time, allowing both users to see movement, tilts, and variant updates instantly.

---

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
