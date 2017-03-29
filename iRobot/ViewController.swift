//
//  ViewController.swift
//  iRobot
//
//  Created by Eddie Koranek on 3/29/17.
//  Copyright © 2017 Eddie Koranek. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
	
	/// Camera Preview
	@IBOutlet weak var previewView: UIView!
	/// Displays recording duration
	@IBOutlet weak var progressView: UIProgressView!
	/// View with long press gesture recognizer
	@IBOutlet weak var recordView: UIView!
	/// The visual effect view behind the record view
	@IBOutlet weak var recordViewEffect: UIVisualEffectView!
	/// The long press gesture to trigger recording
	@IBOutlet weak var longPress: UILongPressGestureRecognizer!
	
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
	
	var timer: Timer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	// MARK: - Setup
	/// set up the timer used to update the progress view
	private func createTimer() {
		timer = Timer(timeInterval: 0.01, repeats: true) { (timer) in
			self.duration += 0.001
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
			if let timer = timer {
				RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
			}
		case .changed:
			return
		case.ended, .cancelled, .failed, .possible:
			timer?.invalidate()
			bounceRecordView(recording: false)
			progressView.setProgress(0.0, animated: true)
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
}

