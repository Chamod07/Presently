import os
import cv2
import numpy as np
import mediapipe as mp
import json
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from PIL import Image, ImageTk
import datetime

class GroundTruthAnnotator:
    def __init__(self, video_path, output_path=None):
        self.video_path = video_path
        self.output_path = output_path or f"{os.path.splitext(video_path)[0]}_ground_truth.json"
        
        # Initialize MediaPipe for initial pose detection
        self.mp_pose = mp.solutions.pose
        self.mp_drawing = mp.solutions.drawing_utils
        self.pose = self.mp_pose.Pose(
            static_image_mode=True,
            model_complexity=2,
            min_detection_confidence=0.5
        )
        
        # Open video
        self.cap = cv2.VideoCapture(video_path)
        self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
        self.fps = self.cap.get(cv2.CAP_PROP_FPS)
        self.current_frame_idx = 0
        
        # Store annotations
        self.annotations = {
            "video_info": {
                "path": video_path,
                "total_frames": self.total_frames,
                "fps": self.fps,
                "annotated_on": datetime.datetime.now().isoformat()
            },
            "frames": {}
        }
        
        # Set up GUI
        self.setup_gui()
    
    def setup_gui(self):
        """Set up the annotation GUI"""
        self.root = tk.Tk()
        self.root.title("Ground Truth Pose Annotator")
        self.root.geometry("1200x800")
        self.root.configure(bg='#f0f0f0')
        
        # Main frame
        main_frame = tk.Frame(self.root, bg='#f0f0f0')
        main_frame.pack(fill="both", expand=True, padx=10, pady=10)
        
        # Left panel - video frame
        left_panel = tk.Frame(main_frame, bg='#f0f0f0', bd=2, relief=tk.GROOVE)
        left_panel.pack(side="left", fill="both", expand=True, padx=5, pady=5)
        
        # Right panel - controls
        right_panel = tk.Frame(main_frame, width=300, bg='#f0f0f0', bd=2, relief=tk.GROOVE)
        right_panel.pack(side="right", fill="y", padx=5, pady=5)
        right_panel.pack_propagate(False)
        
        # Canvas for image
        self.canvas = tk.Canvas(left_panel, bg="black")
        self.canvas.pack(fill="both", expand=True)
        
        # Navigation buttons
        nav_frame = tk.Frame(right_panel, bg='#f0f0f0')
        nav_frame.pack(pady=20)
        
        ttk.Button(nav_frame, text="Previous", command=self.prev_frame).grid(row=0, column=0, padx=5)
        self.frame_label = tk.Label(nav_frame, text=f"Frame: {self.current_frame_idx+1}/{self.total_frames}", bg='#f0f0f0')
        self.frame_label.grid(row=0, column=1, padx=10)
        ttk.Button(nav_frame, text="Next", command=self.next_frame).grid(row=0, column=2, padx=5)
        
        # Frame slider
        slider_frame = tk.Frame(right_panel, bg='#f0f0f0')
        slider_frame.pack(fill="x", pady=10)
        
        tk.Label(slider_frame, text="Frame:", bg='#f0f0f0').pack()
        self.frame_slider = ttk.Scale(slider_frame, from_=1, to=self.total_frames, 
                                     orient="horizontal", command=self.slider_changed)
        self.frame_slider.pack(fill="x", padx=10)
        self.frame_slider.set(1)
        
        # Annotation tools
        annotation_frame = tk.LabelFrame(right_panel, text="Annotation Tools", bg='#f0f0f0')
        annotation_frame.pack(pady=10, fill="x", padx=10)
        
        # Posture quality rating
        quality_frame = tk.Frame(annotation_frame, bg='#f0f0f0')
        quality_frame.pack(fill="x", pady=10, padx=5)
        
        tk.Label(quality_frame, text="Posture Quality:", bg='#f0f0f0').grid(row=0, column=0, sticky="w")
        self.posture_quality = tk.StringVar(value="Good")
        quality_options = ["Excellent", "Good", "Fair", "Poor", "Bad"]
        quality_menu = ttk.Combobox(quality_frame, textvariable=self.posture_quality, values=quality_options, state="readonly")
        quality_menu.grid(row=0, column=1, sticky="ew", padx=5)
        
        # Specific issue checkboxes
        issues_frame = tk.LabelFrame(annotation_frame, text="Issues:", bg='#f0f0f0')
        issues_frame.pack(fill="x", pady=5, padx=5)
        
        self.issues = {
            "uneven_shoulders": tk.BooleanVar(value=False),
            "forward_head": tk.BooleanVar(value=False),
            "slouching": tk.BooleanVar(value=False),
            "tilted_head": tk.BooleanVar(value=False),
            "uneven_hips": tk.BooleanVar(value=False)
        }
        
        for i, (issue, var) in enumerate(self.issues.items()):
            ttk.Checkbutton(issues_frame, text=issue.replace('_', ' ').title(), 
                          variable=var).pack(anchor="w", padx=5, pady=2)
        
        # Manual angle inputs
        angles_frame = tk.LabelFrame(annotation_frame, text="Manual Measurements:", bg='#f0f0f0')
        angles_frame.pack(fill="x", pady=5, padx=5)
        
        self.manual_angles = {
            "shoulder_tilt": tk.StringVar(value=""),
            "head_tilt": tk.StringVar(value=""),
            "forward_lean": tk.StringVar(value=""),
            "spine_angle": tk.StringVar(value="")
        }
        
        row = 0
        for angle_name, var in self.manual_angles.items():
            tk.Label(angles_frame, text=f"{angle_name.replace('_', ' ').title()}:", bg='#f0f0f0').grid(row=row, column=0, sticky="w", padx=5, pady=2)
            ttk.Entry(angles_frame, textvariable=var, width=10).grid(row=row, column=1, sticky="w", padx=5, pady=2)
            tk.Label(angles_frame, text="degrees", bg='#f0f0f0').grid(row=row, column=2, sticky="w")
            row += 1
        
        # Notes field
        notes_frame = tk.LabelFrame(right_panel, text="Notes:", bg='#f0f0f0')
        notes_frame.pack(fill="x", pady=10, padx=10)
        
        self.notes_field = tk.Text(notes_frame, height=4, width=30)
        self.notes_field.pack(fill="x", padx=5, pady=5)
        
        # Action buttons
        action_frame = tk.Frame(right_panel, bg='#f0f0f0')
        action_frame.pack(fill="x", pady=20, padx=10)
        
        ttk.Button(action_frame, text="Save Current Frame", command=self.save_current_frame).pack(fill="x", padx=10, pady=5)
        ttk.Button(action_frame, text="Save All Annotations", command=self.save_annotations).pack(fill="x", padx=10, pady=5)
        ttk.Button(action_frame, text="Exit", command=self.on_close).pack(fill="x", padx=10, pady=5)
        
        # Options frame
        options_frame = tk.LabelFrame(right_panel, text="Options", bg='#f0f0f0')
        options_frame.pack(fill="x", pady=10, padx=10)
        
        # Auto-detect option
        self.auto_detect_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Auto-detect pose", 
                      variable=self.auto_detect_var, command=self.update_frame).pack(anchor="w", padx=5, pady=2)
        
        # Show landmarks option
        self.show_landmarks_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Show landmarks", 
                      variable=self.show_landmarks_var, command=self.update_frame).pack(anchor="w", padx=5, pady=2)

        # Status bar
        self.status_var = tk.StringVar()
        status_bar = tk.Label(self.root, textvariable=self.status_var, bd=1, relief=tk.SUNKEN, anchor=tk.W)
        status_bar.pack(side=tk.BOTTOM, fill=tk.X)
        self.status_var.set("Ready")
        
        # Load initial frame
        self.update_frame()
        
        # Key bindings
        self.root.bind("<Left>", lambda e: self.prev_frame())
        self.root.bind("<Right>", lambda e: self.next_frame())
        self.root.bind("<Control-s>", lambda e: self.save_annotations())
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)
    
    def update_frame(self):
        """Update the displayed frame"""
        # Reset the cap if needed
        if self.current_frame_idx >= self.total_frames:
            self.current_frame_idx = self.total_frames - 1
        
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame_idx)
        ret, self.current_frame = self.cap.read()
        
        if not ret:
            messagebox.showerror("Error", "Could not read frame")
            return
        
        # Update controls with frame details
        self.frame_label.config(text=f"Frame: {self.current_frame_idx+1}/{self.total_frames}")
        self.frame_slider.set(self.current_frame_idx+1)
        
        # Resize frame for display
        display_frame = self.current_frame.copy()
        
        # Auto-detect pose if enabled
        pose_detected = False
        if self.auto_detect_var.get():
            # Process with MediaPipe
            image_rgb = cv2.cvtColor(display_frame, cv2.COLOR_BGR2RGB)
            results = self.pose.process(image_rgb)
            
            if results.pose_landmarks and self.show_landmarks_var.get():
                pose_detected = True
                # Draw pose landmarks
                self.mp_drawing.draw_landmarks(
                    display_frame,
                    results.pose_landmarks,
                    self.mp_pose.POSE_CONNECTIONS,
                    landmark_drawing_spec=self.mp_drawing.DrawingSpec(color=(0, 255, 0), thickness=2, circle_radius=2),
                    connection_drawing_spec=self.mp_drawing.DrawingSpec(color=(0, 0, 255), thickness=2)
                )
                
                # Extract angles
                landmarks = results.pose_landmarks.landmark
                
                try:
                    # Shoulder tilt
                    left_shoulder = [landmarks[self.mp_pose.PoseLandmark.LEFT_SHOULDER].x,
                                    landmarks[self.mp_pose.PoseLandmark.LEFT_SHOULDER].y]
                    right_shoulder = [landmarks[self.mp_pose.PoseLandmark.RIGHT_SHOULDER].x,
                                     landmarks[self.mp_pose.PoseLandmark.RIGHT_SHOULDER].y]
                    
                    from services.pose_analysis_service import calculate_tilt_angle
                    shoulder_tilt = calculate_tilt_angle(left_shoulder, right_shoulder)
                    self.manual_angles['shoulder_tilt'].set(f"{shoulder_tilt:.1f}")
                    
                    # Set other angles if available
                    from services.pose_analysis_service import calculate_head_position, calculate_spine_alignment
                    head_metrics = calculate_head_position(landmarks, self.mp_pose)
                    if head_metrics:
                        if head_metrics['head_tilt'] is not None:
                            self.manual_angles['head_tilt'].set(f"{head_metrics['head_tilt']:.1f}")
                        self.manual_angles['forward_lean'].set(f"{head_metrics['forward_lean']:.1f}")
                    
                    spine_metrics = calculate_spine_alignment(landmarks, self.mp_pose)
                    if spine_metrics:
                        self.manual_angles['spine_angle'].set(f"{spine_metrics['spine_angle']:.1f}")
                except Exception as e:
                    self.status_var.set(f"Error calculating angles: {str(e)}")
        
        # Load annotation if exists
        frame_key = str(self.current_frame_idx)
        if frame_key in self.annotations["frames"]:
            ann = self.annotations["frames"][frame_key]
            
            # Update controls with saved values
            self.posture_quality.set(ann.get("quality", "Good"))
            
            for issue, var in self.issues.items():
                var.set(issue in ann.get("issues", []))
            
            # Update angle fields
            for angle_name, var in self.manual_angles.items():
                if angle_name in ann.get("angles", {}):
                    var.set(ann["angles"][angle_name])
                
            self.notes_field.delete(1.0, tk.END)
            if "notes" in ann:
                self.notes_field.insert(tk.END, ann["notes"])
        
        # Convert frame to RGB for display
        display_frame_rgb = cv2.cvtColor(display_frame, cv2.COLOR_BGR2RGB)
        
        # Update canvas
        h, w = display_frame.shape[:2]
        canvas_width = self.canvas.winfo_width()
        canvas_height = self.canvas.winfo_height()
        
        if canvas_width > 0 and canvas_height > 0:
            # Calculate scale to fit canvas
            scale = min(canvas_width / w, canvas_height / h)
            new_width = int(w * scale)
            new_height = int(h * scale)
            
            # Resize frame to fit canvas
            display_frame_rgb = cv2.resize(display_frame_rgb, (new_width, new_height))
        
        # Convert to PhotoImage
        self.photo = ImageTk.PhotoImage(image=Image.fromarray(display_frame_rgb))
        
        # Update canvas
        self.canvas.config(width=display_frame_rgb.shape[1], height=display_frame_rgb.shape[0])
        self.canvas.create_image(0, 0, image=self.photo, anchor=tk.NW)
        
        # Update status
        status_msg = f"Frame {self.current_frame_idx+1}/{self.total_frames}"
        if pose_detected:
            status_msg += " - Pose detected"
        self.status_var.set(status_msg)
    
    def next_frame(self):
        """Move to next frame"""
        if self.current_frame_idx < self.total_frames - 1:
            self.current_frame_idx += 1
            self.update_frame()
    
    def prev_frame(self):
        """Move to previous frame"""
        if self.current_frame_idx > 0:
            self.current_frame_idx -= 1
            self.update_frame()
    
    def slider_changed(self, value):
        """Handle slider value change"""
        frame_idx = int(float(value)) - 1
        if frame_idx != self.current_frame_idx:
            self.current_frame_idx = frame_idx
            self.update_frame()
    
    def save_current_frame(self):
        """Save annotation for current frame"""
        # Collect issues
        active_issues = [issue for issue, var in self.issues.items() if var.get()]
        
        # Get angles
        angles = {}
        for angle_name, var in self.manual_angles.items():
            value = var.get().strip()
            if value:
                try:
                    angles[angle_name] = float(value)
                except ValueError:
                    messagebox.showerror("Error", f"Invalid value for {angle_name}: {value}")
                    return
        
        # Get notes
        notes = self.notes_field.get(1.0, tk.END).strip()
        
        # Collect all data
        frame_data = {
            "quality": self.posture_quality.get(),
            "issues": active_issues,
            "angles": angles
        }
        
        if notes:
            frame_data["notes"] = notes
        
        # Add timestamp
        frame_data["annotated_at"] = datetime.datetime.now().isoformat()
        
        # Save to annotations
        self.annotations["frames"][str(self.current_frame_idx)] = frame_data
        
        self.status_var.set(f"Frame {self.current_frame_idx+1} annotated")
    
    def save_annotations(self):
        """Save all annotations to file"""
        try:
            with open(self.output_path, 'w') as f:
                json.dump(self.annotations, f, indent=2)
            self.status_var.set(f"Annotations saved to {self.output_path}")
            messagebox.showinfo("Success", f"Annotations saved to {self.output_path}")
        except Exception as e:
            self.status_var.set(f"Error saving annotations: {str(e)}")
            messagebox.showerror("Error", f"Could not save annotations: {str(e)}")
    
    def on_close(self):
        """Handle window close"""
        if self.annotations["frames"]:
            response = messagebox.askyesnocancel("Save Annotations", "Save annotations before exiting?")
            if response is None:  # Cancel
                return
            if response:  # Yes
                self.save_annotations()
        
        self.cap.release()
        self.root.destroy()
    
    def run(self):
        """Run the annotation tool"""
        self.root.mainloop()


def main():
    """Main function to run the annotator"""
    import argparse
    parser = argparse.ArgumentParser(description="Ground truth annotation tool for pose estimation")
    parser.add_argument("--video", help="Path to video file")
    parser.add_argument("--output", help="Path to save annotations")
    
    args = parser.parse_args()
    
    # If no video specified, open file dialog
    video_path = args.video
    if not video_path:
        root = tk.Tk()
        root.withdraw()
        video_path = filedialog.askopenfilename(
            title="Select Video File",
            filetypes=[("Video Files", "*.mp4;*.avi;*.mov;*.mkv"), ("All Files", "*.*")]
        )
        if not video_path:
            print("No video selected. Exiting.")
            return
    
    output_path = args.output
    if not output_path:
        output_path = f"{os.path.splitext(video_path)[0]}_ground_truth.json"
    
    # Initialize and run annotator
    annotator = GroundTruthAnnotator(video_path, output_path)
    annotator.run()

if __name__ == "__main__":
    main()
