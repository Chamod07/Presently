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
    allow_origins=["*"],
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


class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)


# Initialize the connection manager
manager = ConnectionManager()


class PoseEvaluator:
    @classmethod
    def evaluate_pose(cls, landmarks):
        """Comprehensive pose evaluation"""
        evaluation = {
            'good_poses': [],
            'bad_poses': [],
            'overall_feedback': ''
        }

        try:
            # Convert landmarks to a more usable format
            points = {
                'left_shoulder': landmarks[11],
                'right_shoulder': landmarks[12],
                'left_hip': landmarks[23],
                'right_hip': landmarks[24],
                'left_elbow': landmarks[13],
                'right_elbow': landmarks[14],
                'left_wrist': landmarks[15],
                'right_wrist': landmarks[16],
                'head': landmarks[0]
            }

            # Open Stance Check
            shoulder_width = abs(points['left_shoulder'].x - points['right_shoulder'].x)
            hip_width = abs(points['left_hip'].x - points['right_hip'].x)

            if 0.8 <= (shoulder_width / hip_width) <= 1.2:
                evaluation['good_poses'].append('Open Stance')

            # Upright Posture Check
            shoulder_vector = [
                points['right_shoulder'].x - points['left_shoulder'].x,
                points['right_shoulder'].y - points['left_shoulder'].y
            ]
            vertical_angle = np.degrees(np.arctan2(shoulder_vector[1], shoulder_vector[0]))

            if 170 <= abs(vertical_angle) <= 190:
                evaluation['good_poses'].append('Upright Posture')
            else:
                evaluation['bad_poses'].append('Slouching')

            # Arm Position Check
            left_arm_cross = abs(points['left_shoulder'].x - points['left_wrist'].x)
            right_arm_cross = abs(points['right_shoulder'].x - points['right_wrist'].x)

            if left_arm_cross < 0.2 and right_arm_cross < 0.2:
                evaluation['bad_poses'].append('Crossed Arms')

            # Generate Overall Feedback
            if len(evaluation['good_poses']) > 1:
                evaluation['overall_feedback'] = 'Great presentation posture!'
            elif len(evaluation['bad_poses']) > 1:
                evaluation['overall_feedback'] = 'Work on your body language.'
            else:
                evaluation['overall_feedback'] = 'Decent presentation stance.'

        except Exception as e:
            print(f"Pose evaluation error: {e}")
            evaluation['overall_feedback'] = 'Unable to fully analyze pose.'

        return evaluation


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            img_data = base64.b64decode(data.split(',')[1])
            np_arr = np.frombuffer(img_data, np.uint8)
            img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            results = pose.process(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))

            if results.pose_landmarks:
                # Evaluate pose
                pose_evaluation = PoseEvaluator.evaluate_pose(results.pose_landmarks.landmark)

                # Print the evaluation results to the terminal
                print("Pose Evaluation:", json.dumps(pose_evaluation, indent=2))

                # Combine landmarks and evaluation
                response = {
                    'pose_evaluation': pose_evaluation
                }

                # Send evaluation back to client
                await websocket.send_text(json.dumps(response))
            else:
                # Send empty response if no pose detected
                await websocket.send_text(json.dumps({'pose_evaluation': {}}))

    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        manager.disconnect(websocket)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
