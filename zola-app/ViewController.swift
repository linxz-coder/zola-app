//
//  ViewController.swift
//  zola-app
//
//  Created by linxiaozhong on 2024/11/27.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var dateInput: UITextField!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var authorInput: UITextField!
    @IBOutlet weak var contentInput: UITextView!
    @IBOutlet weak var tag1: UITextField!
    @IBOutlet weak var tag2: UITextField!
    @IBOutlet weak var tag3: UITextField!
    
    var structureText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let defaultDate = dateFormatter.string(from: Date())
        
        // 根据内容动态构建 tags 数组
        var tags: [String] = []
        if let tag1Text = tag1.text, !tag1Text.isEmpty {
            tags.append(tag1Text)
            if let tag2Text = tag2.text, !tag2Text.isEmpty {
                tags.append(tag2Text)
                if let tag3Text = tag3.text, !tag3Text.isEmpty {
                    tags.append(tag3Text)
                }
            }
        }
        
        let taxonomySection = tags.isEmpty ? "" : """
                [taxonomies]
                tags = ["\(tags.joined(separator: "\", \""))"]
                
                """
        
        return """
        +++
        title = "\(titleInput.text ?? "")"
        date = \(dateInput.text?.isEmpty == false ? dateInput.text! : defaultDate)
        authors = ["\(authorInput.text ?? "")"]
        \(taxonomySection)
        +++
        
        \(contentInput.text ?? "")
        
        """
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 设置所有输入框的delegate
        dateInput.delegate = self
        titleInput.delegate = self
        authorInput.delegate = self
        contentInput.delegate = self
        tag1.delegate = self
        tag2.delegate = self
        tag3.delegate = self
        
        // 初始隐藏 tag2 和 tag3
        tag2.isHidden = true
        tag3.isHidden = true
        
        // 添加文本变化监听器
        tag1.addTarget(self, action: #selector(tag1TextChanged), for: .editingChanged)
        tag2.addTarget(self, action: #selector(tag2TextChanged), for: .editingChanged)
        
    }
    
    func updateUI(){
        dateInput.text = ""
        titleInput.text = ""
        //authorInput.text = ""
        contentInput.text = ""
        tag1.text = ""
        tag2.text = ""
        tag3.text = ""
    }
    
    @objc func tag1TextChanged() {
        tag2.isHidden = tag1.text?.isEmpty ?? true
    }
    
    @objc func tag2TextChanged() {
        tag3.isHidden = tag2.text?.isEmpty ?? true
    }
    
    
    //跳到第二屏
    @IBAction func sourceTextPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToSource", sender: self)
    }
    
    //同步zola网站
    @IBAction func zolaSyncPressed(_ sender: UIButton) {
        
        //处理optional，如果filename存在且不为空，才往下执行。
        guard let filename = titleInput.text, !filename.isEmpty else { return }
        
        //确认上传界面
        let confirmAlert = UIAlertController(title: "Confirm Upload",
                                             message: "Do you want to upload this file?",
                                             preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            self?.showPathSelectionAlert(filename: filename)
        }
        
        confirmAlert.addAction(cancelAction)
        confirmAlert.addAction(confirmAction)
        
        present(confirmAlert, animated: true)
    }
    
    //用户选择路径
    func showPathSelectionAlert(filename: String) {
        let pathAlert = UIAlertController(title: "Select Upload Path",
                                          message: "Choose or enter a path (default: content)",
                                          preferredStyle: .actionSheet)
        
        // 预定义的路径选项
        let paths = ["/content/blog", "/content/shorts", "/content/books"]
        
        // 添加预定义路径选项
        for path in paths {
            let pathAction = UIAlertAction(title: path, style: .default) { [weak self] _ in
                self?.uploadContent(filename: filename, path: path)
            }
            pathAlert.addAction(pathAction)
        }
        
        // 添加自定义路径选项
        let customAction = UIAlertAction(title: "Custom Path", style: .default) { [weak self] _ in
            self?.showCustomPathInput(filename: filename)
        }
        
        // 添加默认路径选项
        let defaultAction = UIAlertAction(title: "Default (content)", style: .default) { [weak self] _ in
            self?.uploadContent(filename: filename, path: "/content")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        pathAlert.addAction(customAction)
        pathAlert.addAction(defaultAction)
        pathAlert.addAction(cancelAction)
        
        present(pathAlert, animated: true)
    }
    
    //上传content
    func uploadContent(filename: String, path: String) {
        let content = structureText
        // 移除路径开头的斜杠（如果存在）
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        
        GitHubService.shared.uploadContent(content: content,
                                           filename: "\(filename).md",
                                           path: cleanPath) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showAlert(message: "Successfully uploaded to \(path)!")
                    self?.updateUI()
                case .failure(let error):
                    self?.showAlert(message: "Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    //upload button的通知事件
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
    //自定义路径
    func showCustomPathInput(filename: String) {
        let customPathAlert = UIAlertController(title: "Enter Custom Path",
                                                message: "Start with /content/",
                                                preferredStyle: .alert)
        
        customPathAlert.addTextField { textField in
            textField.placeholder = "/content/your-path"
            textField.text = "/content/"
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            guard let customPath = customPathAlert.textFields?.first?.text,
                  !customPath.isEmpty else { return }
            self?.uploadContent(filename: filename, path: customPath)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        customPathAlert.addAction(confirmAction)
        customPathAlert.addAction(cancelAction)
        
        present(customPathAlert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSource"{
            if let destinationVC = segue.destination as? SourceTextController {
                destinationVC.textToDisplay = structureText
            }
        }
    }
    
}

//MARK: - UIViewDelegate
extension ViewController: UITextFieldDelegate, UITextViewDelegate{
    // 当文本变化时更新Markdown预览
}

