//
//  ATItemCell.swift
//  Babylonian
//
//  Created by Dongning Wang on 4/2/16.
//  Copyright © 2016 Eric Smith. All rights reserved.
//

import UIKit

class ATItemCell: UITableViewCell {

    var audioPath : String!
    @IBOutlet weak var audioPlayer: UIButton!
    
    @IBOutlet weak var transcript: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func playButtonPressed(sender: UIButton) {
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}