import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense
from tensorflow.keras.models import Model
import numpy as np
from PIL import Image

# -------- MODEL SETUP --------
def build_model(num_classes):
    base_model = EfficientNetB0(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    x = GlobalAveragePooling2D()(base_model.output)
    output = Dense(num_classes, activation='softmax')(x)
    model = Model(inputs=base_model.input, outputs=output)
    return model

# Mock class names for illustration (replace with real ones if training custom)
class_names = [
    "Apple Scab", "Apple Black Rot", "Apple Cedar Rust", "Apple Healthy",
    "Blueberry Healthy", "Cherry Healthy", "Cherry Powdery Mildew",
    "Corn Gray Leaf Spot", "Corn Common Rust", "Corn Healthy",
    "Corn Northern Leaf Blight", "Grape Black Rot", "Grape Esca",
    "Grape Healthy", "Grape Leaf Blight", "Orange Haunglongbing",
    "Peach Bacterial Spot", "Peach Healthy", "Pepper Bacterial Spot",
    "Pepper Healthy", "Potato Early Blight", "Potato Healthy",
    "Potato Late Blight", "Raspberry Healthy", "Soybean Healthy",
    "Squash Powdery Mildew", "Strawberry Healthy", "Strawberry Leaf Scorch",
    "Tomato Bacterial Spot", "Tomato Early Blight", "Tomato Healthy",
    "Tomato Late Blight", "Tomato Leaf Mold", "Tomato Septoria Leaf Spot",
    "Tomato Spider Mites", "Tomato Target Spot", "Tomato Mosaic Virus",
    "Tomato Yellow Leaf Curl Virus"
]

# Load a dummy model (weights should be trained if using custom data)
model = build_model(len(class_names))

# -------- PREDICTION FUNCTION --------
def preprocess_image(image_path):
    image = Image.open(image_path).convert('RGB')
    image = image.resize((224, 224))
    image_array = np.array(image) / 255.0
    return np.expand_dims(image_array, axis=0)

def predict_disease(image_path):
    image = preprocess_image(image_path)
    predictions = model.predict(image)[0]
    top_class = np.argmax(predictions)
    return {
        'label': class_names[top_class],
        'confidence': float(predictions[top_class])
    }

# --------- USAGE EXAMPLE ---------
if __name__ == '__main__':
    img_path = 'download (1).jpeg'  # Put your test leaf image here
    try:
        result = predict_disease(img_path)
        print(f"\n✅ Prediction: {result['label']}")
        print(f"🎯 Confidence: {result['confidence'] * 100:.2f}%")
    except Exception as e:
        print("❌ Error:", e)
