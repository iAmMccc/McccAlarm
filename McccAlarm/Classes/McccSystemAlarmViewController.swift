//
//  McccSystemAlarmViewController.swift
//  McccAlarm
//
//  Created by qixin on 2025/10/24.
//

import UIKit
import AVFoundation
import AudioToolbox

// MARK: - 协议定义
public protocol McccSystemAlarmViewControllerDelegate: AnyObject {
    func alarmViewControllerDidTapRepeat(_ controller: McccSystemAlarmViewController, alarmId: String)
    func alarmViewControllerDidTapStop(_ controller: McccSystemAlarmViewController, alarmId: String)
}

// MARK: - 控制器实现
public class McccSystemAlarmViewController: UIViewController {
    
    // MARK: - 公共属性配置
    public weak var delegate: McccSystemAlarmViewControllerDelegate?
    
    public var showsRepeatButton: Bool = true
    public var backgroundColor: UIColor? = .black
    public var soundName: String?
    
    // MARK: - 基本参数
    private let alarmTitle: String
    private let time: Date
    public let alarmId: String
    
    private var player: AVAudioPlayer?
    
    // MARK: - UI 元素
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    
    private let clockIconView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let image = UIImage(systemName: "alarm.fill", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .white.withAlphaComponent(0.6)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel = UILabel()
    private lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [clockIconView, titleLabel])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()
    
    private let timeLabel = UILabel()
    
    private let repeatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重复", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemOrange
        button.titleLabel?.font = .systemFont(ofSize: 38, weight: .medium)
        button.layer.cornerRadius = 50
        button.layer.masksToBounds = true
        button.alpha = 0.85
        return button
    }()
    
    private let stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("停止", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.titleLabel?.font = .systemFont(ofSize: 38, weight: .medium)
        button.layer.cornerRadius = 55
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        button.layer.borderWidth = 1
        button.alpha = 0.85
        return button
    }()
    
    
    // MARK: - 初始化
    public init(title: String, time: Date, alarmId: String) {
        self.alarmTitle = title
        self.time = time
        self.alarmId = alarmId
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        setupActions()
        startFeedback()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopFeedback()
    }
    
    
    // MARK: - 初始化 UI
    private func setupUI() {
        view.addSubview(blurView)
        view.addSubview(timeLabel)
        view.addSubview(titleStack)
        view.addSubview(stopButton)
        
        if showsRepeatButton {
            view.addSubview(repeatButton)
        }
        
        [blurView, titleStack, timeLabel, repeatButton, stopButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        view.backgroundColor = backgroundColor
        
        titleLabel.text = alarmTitle
        titleLabel.font = .systemFont(ofSize: 30, weight: .medium)
        titleLabel.textColor = .white.withAlphaComponent(0.6)
        titleLabel.textAlignment = .center
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: time)
        timeLabel.font = .systemFont(ofSize: 150, weight: .semibold)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        timeLabel.alpha = 0.7
        
        clockIconView.addSymbolEffect(.wiggle, options: .repeating.speed(2))
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            timeLabel.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            titleStack.bottomAnchor.constraint(equalTo: timeLabel.topAnchor),
            titleStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stopButton.heightAnchor.constraint(equalToConstant: 110)
        ])
        
        if showsRepeatButton {
            NSLayoutConstraint.activate([
                repeatButton.bottomAnchor.constraint(equalTo: stopButton.topAnchor, constant: -15),
                repeatButton.leadingAnchor.constraint(equalTo: stopButton.leadingAnchor),
                repeatButton.trailingAnchor.constraint(equalTo: stopButton.trailingAnchor),
                repeatButton.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
    }
    
    private func setupActions() {
        stopButton.addTarget(self, action: #selector(didTapStop), for: .touchUpInside)
        repeatButton.addTarget(self, action: #selector(didTapRepeat), for: .touchUpInside)
    }
    
    
    // MARK: - 反馈逻辑
    private func startFeedback() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        if let soundName = soundName, let soundURL = Bundle.main.url(forResource: soundName, withExtension: nil) {
            do {
                player = try AVAudioPlayer(contentsOf: soundURL)
                player?.numberOfLoops = -1
                player?.play()
            } catch {
                print("播放铃声失败: \(error)")
            }
        }
    }
    
    private func stopFeedback() {
        player?.stop()
    }
    
    
    // MARK: - 按钮行为
    @objc private func didTapRepeat() {
        stopFeedback()
        dismiss(animated: true)
        delegate?.alarmViewControllerDidTapRepeat(self, alarmId: alarmId)
    }
    
    @objc private func didTapStop() {
        stopFeedback()
        dismiss(animated: true)
        delegate?.alarmViewControllerDidTapStop(self, alarmId: alarmId)
    }
}

