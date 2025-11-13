# Reciept-Analizar
This is a minimal MVP (Minimum Viable Product) of a grocery receipt scanning app built entirely with SwiftUI for iOS 17+.

It uses Apple's VisionKit to scan documents, Vision to perform OCR, a simple rule-based parser to extract items, and Swift Charts to display a spending dashboard.

🎯 Features

Scan Receipts: Uses the native VNDocumentCameraViewController for high-quality scanning.

OCR: Extracts text from scanned images using VNRecognizeTextRequest.

Parsing: A simple regex parser finds item names and prices.

Classification: A rule-based classifier (CategoryClassifier.swift) categorizes items (e.g., "Milk" -> "Dairy").

Dashboard: A Charts pie chart shows spending by category, plus a total spend summary.

Storage: All data is stored in a shared AppState ObservableObject (no database).

Design: Minimalist, Apple-style design that fully supports Light and Dark Modes.

🛠 How to Run

Xcode: Open Xcode 15 or newer.

Create Project: Create a new SwiftUI app project (File > New > Project... > iOS > App). Name it GroceryScanLite.

Add Files: Drag all the .swift and .md files from this folder into their respective groups in the Xcode project navigator. For example, place GroceryModels.swift and SampleData.swift into a Models group.

Install Frameworks: No external frameworks are needed. However, you must add Vision.framework, VisionKit.framework, and Charts.framework to your target's "Frameworks, Libraries, and Embedded Content" section (though Xcode 15+ usually links these automatically for SwiftUI projects).

Run on Device: This project must be run on a physical iOS device (iPhone or iPad) running iOS 17.0+ to use the VNDocumentCameraViewController. The scanner will not work on the Simulator.

🧠 Replacing the Classifier with Core ML

The app currently uses a simple, rule-based classifier in CategoryClassifier.swift. You can easily replace this with a trained Core ML model.

Get a Model: Obtain a .mlmodel file (e.g., a text classifier) that takes an item name (String) as input and outputs a category (String).

Add Model: Drag your YourModelName.mlmodel file into the Resources group in Xcode. Make sure it's added to the app target.

Update Code:

Open Services/CategoryClassifier.swift.

Comment out the classify function.

Uncomment the classifyWithCoreML function (and rename it to classify).

Change FoodCategoryClassifier to your model's generated class name.

Update the input (text:) and output (prediction.label) properties to match your model's.

