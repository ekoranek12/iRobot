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
	
	/// Button for canceling recording
	@IBOutlet weak var cancelButton: UIButton!
	/// Button for submitting the recording
	@IBOutlet weak var submitButton: UIButton!
	
	var captureSession: AVCaptureSession?
	var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	
	var playerLooper: AVPlayerLooper?
	var playerLayer: AVPlayerLayer?
	
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
	
	/// Recording output location TEMPORARY
	let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("videoOutput").appendingPathExtension("mp4")
	let finalURL = FileManager.default.temporaryDirectory.appendingPathComponent("finalVideo").appendingPathExtension("mp4")
	let fileOutput = AVCaptureMovieFileOutput()
	var timer: Timer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		overlayImageView.image = IRobotStyleKit.imageOfCameraOverlay
		createVideoPreviewLayer()
		toggleButton(visibility: false, duration: 0.0)
	}
	
	// MARK: - Setup
	/// set up the timer used to update the progress view
	private func createTimer() {
		timer = Timer(timeInterval: 0.01, repeats: true) { (timer) in
			self.duration += 0.001
		}
	}
	
	/// Setup the video preview layer
	private func createVideoPreviewLayer() {
		// Camera Setup: http://www.appcoda.com/barcode-reader-swift/
		guard let frontCamera = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) else { return }
		
		do {
			let input = try AVCaptureDeviceInput(device: frontCamera)
			
			captureSession = AVCaptureSession()
			captureSession?.addInput(input)
			captureSession?.addOutput(fileOutput)
			
			var videoConnection:AVCaptureConnection?
			
			// http://stackoverflow.com/questions/30406417/need-to-mirror-video-orientation-and-handle-rotation-when-using-front-camera/30646150
			// Flip camera output
			for connection in self.fileOutput.connections {
				for port in (connection as AnyObject).inputPorts! {
					if (port as AnyObject).mediaType == AVMediaTypeVideo {
						videoConnection = connection as? AVCaptureConnection
						if videoConnection!.isVideoMirroringSupported {
							videoConnection!.isVideoMirrored = true
						}
					}
				}
			}
			
			videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
			videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
			let width = UIScreen.main.bounds.width
			videoPreviewLayer?.frame = CGRect(x: 0, y: 0, width: width, height: width * (1920.0 / 1280.0))
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
			playerLayer?.removeFromSuperlayer()
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
			toggleButton(visibility: true)
		}
	}
	
	@IBAction func tapCancel() {
		toggleButton(visibility: false)
		playerLayer?.removeFromSuperlayer()
	}
	
	@IBAction func tapSubmit() {
		magicAndCrap()
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
	
	/// Show or hide the cancel and submit buttons
	///
	/// - Parameters:
	///   - visible: true if the buttons should be shown; false otherwise
	///   - duration: How long the animation should take. Defaults to 0.3
	private func toggleButton(visibility visible: Bool, duration: TimeInterval = 0.3) {
			UIView.animate(withDuration: duration) {
				self.cancelButton.isEnabled = visible
				self.cancelButton.alpha = visible ? 1.0 : 0.0
				self.submitButton.isEnabled = visible
				self.submitButton.alpha = visible ? 1.0 : 0.0
				
				self.longPress.isEnabled = !visible
		}
	}
	
	// MARK: - AVCaptureFileOutputRecordingDelegate
	func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
		if error != nil {
			print(error)
		} else {
			print(outputFileURL)
			print(outputFileURL == fileURL)
			play(videoAt: outputFileURL)
		}
	}
	
	/// Plays a video from a URL in the playerLayer
	///
	/// - Parameter URL: A file URL of the video to be played
	private func play(videoAt URL: URL) {
		let player = AVQueuePlayer()
		playerLayer = AVPlayerLayer(player: player)
		let playerItem = AVPlayerItem(url: URL)
		playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
		previewView.layer.addSublayer(playerLayer!)
		let width = UIScreen.main.bounds.width
		playerLayer?.frame = CGRect(x: 0, y: 0, width: width, height: width * (1920.0 / 1280.0))
		playerLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
		player.play()
	}
	
	private func magicAndCrap() {
		try? FileManager.default.removeItem(at: finalURL)
		
		let asset = AVAsset(url: fileURL)
		guard let assetTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first else { print("No video track!"); return }
		
		let composition = AVMutableVideoComposition()
		composition.renderSize = CGSize(width: 1280, height: 1920)
		composition.frameDuration = CMTimeMake(1, 30)
		
		let instruction = AVMutableVideoCompositionInstruction()
		instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: asset.duration)
		
		let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
		
		let scale = CGFloat(1280.0 / assetTrack.naturalSize.height)
		let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
		let rotateTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
		let offsetTransform = CGAffineTransform(translationX: assetTrack.naturalSize.height, y: -128) // Yeah. Idk either.
		
		let finalTransform = rotateTransform.concatenating(offsetTransform).concatenating(scaleTransform)
		transformer.setTransform(finalTransform, at: kCMTimeZero)
		instruction.layerInstructions = [transformer]
		composition.instructions = [instruction]
		
		// Overlay
		let overlayLayer = CALayer()
		overlayLayer.contents = IRobotStyleKit.imageOfCameraOverlay.cgImage
		overlayLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 1280, height: 1920))
		overlayLayer.masksToBounds = true
		
		let videoLayer = CALayer()
		videoLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 1280, height: 1920))
		
		let parentLayer = CALayer()
		parentLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 1280, height: 1920))
		parentLayer.addSublayer(videoLayer)
		parentLayer.addSublayer(overlayLayer)
		
		composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
		//End overlay
		
		let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
		exporter?.videoComposition = composition
		exporter?.outputURL = finalURL
		exporter?.outputFileType = AVFileTypeMPEG4
		
		exporter?.exportAsynchronously(completionHandler: {
			let player = AVPlayer(url: self.finalURL)
			let playerController = AVPlayerViewController()
			playerController.player = player
			self.present(playerController, animated: true, completion: nil)
		})
	}
}

