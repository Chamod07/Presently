import base64
import cv2
import numpy as np
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import mediapipe as mp
import json
import io

app = FastAPI()

# Add CORS middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

mp_pose = mp.solutions.pose
pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=1,
    smooth_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)
mp_drawing = mp.solutions.drawing_utils


class ConnectionManager:
    def __init__(self):
        self.active_connections = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)


manager = ConnectionManager()


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            # Remove data URI prefix and decode base64
            img_data = base64.b64decode(data.split(',')[1])

            # Convert to numpy array
            np_arr = np.frombuffer(img_data, np.uint8)

            # Decode image
            img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            # Process image with MediaPipe
            results = pose.process(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))

            if results.pose_landmarks:
                # Extract landmark coordinates
                landmarks = []
                for landmark in results.pose_landmarks.landmark:
                    landmarks.append({
                        'x': landmark.x,
                        'y': landmark.y,
                        'z': landmark.z,
                        'visibility': landmark.visibility
                    })

                # Send landmarks back to client
                await websocket.send_text(json.dumps(landmarks))
            else:
                # Send empty landmarks if no pose detected
                await websocket.send_text(json.dumps([]))

    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        manager.disconnect(websocket)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)