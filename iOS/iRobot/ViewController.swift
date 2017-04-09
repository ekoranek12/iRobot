//
//  ViewController.swift
//  iRobot
//
//  Created by Eddie Koranek on 3/29/17.
//  Copyright © 2017 Eddie Koranek. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController, UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate {
	
	/// Camera Preview
	@IBOutlet weak var previewView: UIView!
	/// Displays the overview oval during recording
	@IBOutlet weak var overlayImageView: UIImageView!
	/// Displays recording duration
	@IBOutlet weak var progressView: UIProgressView!
	/// View with long press gesture recognizer
	@IBOutlet weak var recordView: UIView!
	/// The visual effect view behind the record view
	@IBOutlet weak var recordViewEffect: UIVisualEffectView!
	/// The long press gesture to trigger recording
	@IBOutlet weak var longPress: UILongPressGestureRecognizer!
	
	var captureSession: AVCaptureSession?
	var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	var playerLooper: AVPlayerLooper?
	
	/// The amount of time the current timer has been firing
	/// Updates the progress view to reflect recording progress and limit
	/// resets when duration after 10 seconds
	private var duration: Float = 0.0 {
		didSet {
			if duration == 10 {
				timer?.invalidate()
			}
			progressView.setProgress(duration, animated: false)
		}
	}
	
	let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("videoOutput").appendingPathExtension("mp4")
	let fileOutput = AVCaptureMovieFileOutput()
	var timer: Timer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		overlayImageView.image = IRobotStyleKit.imageOfCameraOverlay
		createVideoPreviewLayer()
	}
	
	// MARK: - Setup
	/// set up the timer used to update the progress view
	private func createTimer() {
		timer = Timer(timeInterval: 0.01, repeats: true) { (timer) in
			self.duration += 0.001
		}
	}
	
	private func createVideoPreviewLayer() {
		// Camera Setup: http://www.appcoda.com/barcode-reader-swift/
		guard let frontCamera = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) else { return }
		
		do {
			let input = try AVCaptureDeviceInput(device: frontCamera)
			
			captureSession = AVCaptureSession()
			captureSession?.addInput(input)
		
//			fileOutput.maxRecordedDuration = CMTime(seconds: 10, preferredTimescale: CMTimeScale.allZeros)
			captureSession?.addOutput(fileOutput)
			
			videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
			videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
			videoPreviewLayer?.frame = view.layer.bounds
			previewView.layer.addSublayer(videoPreviewLayer!)
			
			print("Starting capture session")
			captureSession?.startRunning()
			
		} catch {
			print("Error starting capture session: \(error)")
			return
		}
	}
	
	// MARK: - Actions
	/// Triggered by the long press gesture
	@IBAction func holdRecord() {
		switch longPress.state {
		case .began:
			bounceRecordView(recording: true)
			duration = 0.0
			createTimer()
			fileOutput.startRecording(toOutputFileURL: fileURL, recordingDelegate: self)
			if let timer = timer {
				RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
			}
		case .changed:
			return
		case.ended, .cancelled, .failed, .possible:
			timer?.invalidate()
			bounceRecordView(recording: false)
			progressView.setProgress(0.0, animated: true)
			fileOutput.stopRecording()
		}
	}
	
	// MARK: - Animations
	private func bounceRecordView(recording: Bool) {
		let outerTransform = recording ?  CGAffineTransform(scaleX: 1.1, y: 1.1) : CGAffineTransform.identity
		let innerTransform = recording ?  CGAffineTransform(scaleX: 0.8, y: 0.8) : CGAffineTransform.identity
		
		UIView.animate(withDuration: 0.2) { 
			self.recordViewEffect.transform = outerTransform
			self.recordView.transform = innerTransform
		}
	}
	
	// MARK: - AVCaptureFileOutputRecordingDelegate
	func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
		if error != nil {
			print(error)
		} else {
			print(outputFileURL)
			play(videoAt: outputFileURL)
		}
	}
	
	// test
	private func play(videoAt URL: URL) {
		let player = AVQueuePlayer()
		let playerLayer = AVPlayerLayer(player: player)
		let playerItem = AVPlayerItem(url: URL)
		playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
		previewView.layer.addSublayer(playerLayer)
		playerLayer.frame = previewView.bounds
		playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		player.play()
	}
}

