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
	
	/// Triggered by the long press gesture
	@IBAction func holdRecord() {
		switch longPress.state {
		case .began:
			duration = 0.0
			createTimer()
			if let timer = timer {
				RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
			}
		case .changed:
			return
		case.ended, .cancelled, .failed, .possible:
			timer?.invalidate()
			progressView.setProgress(0.0, animated: true)
		}
	}
	
	
	/// set up the timer used to update the progress view
	private func createTimer() {
		timer = Timer(timeInterval: 0.01, repeats: true) { (timer) in
			self.duration += 0.001
		}
	}
}

