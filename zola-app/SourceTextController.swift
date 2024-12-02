//
//  SourceTextController.swift
//  zola-app
//
//  Created by linxiaozhong on 2024/11/28.
//

import UIKit

class SourceTextController: UIViewController {
    
    var textToDisplay: String = ""
    
    @IBOutlet weak var structureText: UITextView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        structureText.text = textToDisplay
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
