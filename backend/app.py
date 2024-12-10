from flask import Flask, request, jsonify
import os
import cv2
import face_recognition
import numpy as np
from werkzeug.utils import secure_filename

app = Flask(__name__)
UPLOAD_FOLDER = './uploaded_images'
ENCODINGS_FILE = './face_encodings.npy'
NAMES_FILE = './face_names.npy'

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Initialize known encodings and names
if os.path.exists(ENCODINGS_FILE) and os.path.exists(NAMES_FILE):
    known_face_encodings = np.load(ENCODINGS_FILE, allow_pickle=True).tolist()
    known_face_names = np.load(NAMES_FILE, allow_pickle=True).tolist()
else:
    known_face_encodings = []
    known_face_names = []

@app.route('/upload', methods=['POST'])
def upload_image():
    if 'image' not in request.files or 'name' not in request.form:
        return jsonify({'message': 'Image and name are required'}), 400
    
    image = request.files['image']
    name = request.form['name']

    # Save the image
    filename = secure_filename(image.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    image.save(filepath)

    # Encode the face
    uploaded_image = face_recognition.load_image_file(filepath)
    try:
        face_encoding = face_recognition.face_encodings(uploaded_image)[0]
    except IndexError:
        return jsonify({'message': 'No face found in the image'}), 400

    # Add the new encoding and name
    known_face_encodings.append(face_encoding)
    known_face_names.append(name)

    # Save encodings and names to files
    np.save(ENCODINGS_FILE, known_face_encodings)
    np.save(NAMES_FILE, known_face_names)

    return jsonify({'message': 'User registered successfully'}), 200

@app.route('/authenticate', methods=['POST'])
def authenticate():
    if 'image' not in request.files:
        return jsonify({'message': 'Image is required'}), 400
    
    image = request.files['image']

    # Save the image temporarily
    filename = secure_filename(image.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    image.save(filepath)

    # Load the image and encode it
    uploaded_image = face_recognition.load_image_file(filepath)
    try:
        face_encoding = face_recognition.face_encodings(uploaded_image)[0]
    except IndexError:
        os.remove(filepath)  # Delete the temp file if no face is found
        return jsonify({'message': 'No face found in the image'}), 400

    # Match with known faces
    matches = face_recognition.compare_faces(known_face_encodings, face_encoding)
    face_distances = face_recognition.face_distance(known_face_encodings, face_encoding)
    best_match_index = np.argmin(face_distances) if len(face_distances) > 0 else None

    # Delete the temporary image file after authentication
    os.remove(filepath)

    if best_match_index is not None and matches[best_match_index]:
        return jsonify({'message': 'Login successful', 'name': known_face_names[best_match_index]}), 200
    else:
        return jsonify({'message': 'Authentication failed'}), 401

if __name__ == '__main__':
    app.run(debug=True)