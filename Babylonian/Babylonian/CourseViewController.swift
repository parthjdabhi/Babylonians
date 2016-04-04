//
//  CourseViewController.swift
//  Babylonian
//
//  Created by Dongning Wang on 4/2/16.
//  Copyright © 2016 Eric Smith. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import Parse

class CourseViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioRecorderDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var currentCourse: BBCourse!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioURL = NSURL()
    var imagePicker = UIImagePickerController()
    
    @IBOutlet weak var courseTableView: LPRTableView!
    
    @IBOutlet weak var tableEditButton: UIButton!
    //TODO: initwithCourseId
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(CourseViewController.backTapped))
        
        self.imagePicker.delegate = self

        self.courseTableView.delegate = self
        self.courseTableView.dataSource = self
        self.courseTableView.longPressReorderEnabled = false
        
        if let _=(self.navigationController as! BBCourseNavController).currentCourse {
            //has a value already
            print("currentCourse has a value already")
            
        }
        else{
            //let ref = DataService.dataService.COURSE_REF.childByAutoId()
            //uncomment above and comment below to actually create new course.
            let ref = DataService.dataService.COURSE_REF.childByAppendingPath("/-KEPJobHpCZ1z_4xOI6C")
            (self.navigationController as! BBCourseNavController).currentCourse = BBCourse(ref: ref, author: NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String)
        }
        self.currentCourse = (self.navigationController as! BBCourseNavController).currentCourse
        
        //TODO: should update new value only
        
        self.currentCourse.courseRef.observeEventType(.Value, withBlock: { snapshot in
            
            if let content = snapshot.value.objectForKey("content"){
                
                for item in content as! [String:NSDictionary]{
                    let item_ref = self.currentCourse.contentRef.childByAppendingPath(item.0)
                    if let im_ref = item.1[COURSE_ITEM_IMAGE] {
                        
                        let courseItem = ImageItem(ref: item_ref, courseImage: im_ref as! String,order: item.1[COURSE_ITEM_ORDER] as! Int)
                        self.currentCourse.addCourseItem(courseItem)
                        
                    }
                    else if let text_ref = item.1[COURSE_ITEM_TEXT]  {
                        let courseItem = ATItem(ref: item_ref,courseText: text_ref as! String, courseAudio: item.1[COURSE_ITEM_AUDIO] as! String, order: item.1[COURSE_ITEM_ORDER] as! Int)
                        self.currentCourse.addCourseItem(courseItem)
                    }
                }
                self.courseTableView.reloadData()
            }
            else{
                //course without content
                
            }
            
            
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        
        //prepare for recording
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if allowed {
                        //self.loadRecordingUI()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func editButton(sender: UIButton) {
         //TODO: change tableview status
        
        if self.courseTableView.editing {
            self.courseTableView.setEditing(false, animated: true)
            self.tableEditButton.setTitle("Edit", forState: .Normal)
        }
        else{
            self.courseTableView.setEditing(true, animated: true)
            self.tableEditButton.setTitle("Done", forState: .Normal)
        }
        
    }

    @IBAction func addImageItem(sender: UIButton) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum;
            imagePicker.allowsEditing = true
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
        //TODO: image don't upload
        let data = UIImageJPEGRepresentation(image!, 1)
        let imageFile = PFFile(name: "image.jpg", data: data!)
        
        let pObject = PFObject(className: "Image")
        pObject[PARSE_IMAGE_FILENAME]  = imageFile
        
        pObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if success {
                self.currentCourse.addNewImageItem((imageFile?.url)!)
            }else {
                print(error)
            }
        }
        
    }
    
    @IBAction func nextButton(sender: UIButton) {
        //TODO: check item number
        //TODO: Push to the next view
    }
    
    @IBAction func recordButtonPressed(sender: UIButton) {
        startRecording()
    }
    
    @IBAction func recordButtonReleased(sender: UIButton) {
        finishRecording(success: true)
        
        let data = NSData(contentsOfURL: self.audioURL)
        let audioFile = PFFile(name: "audio.m4a", data: data!)
        
        let pObject = PFObject(className: "Audio")
        pObject[PARSE_AUDIO_FILENAME]  = audioFile
        
        pObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if success {
                self.currentCourse.addNewATItem("", courseAudio: (audioFile?.url)!)
            }else {
                print(error)
            }
        }
        
    }
    
    
    
    func startRecording() {
        let audioFilename = DataService.dataService.LOCAL_DIR+"/recording.m4a"
        self.audioURL = NSURL(fileURLWithPath: audioFilename)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 1 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(URL: self.audioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
        } catch {
            finishRecording(success: false)
        }
    }
    func finishRecording(success success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
    }
    
//    @IBAction func testplay(sender: UIButton) {
//        do{
//            self.audioPlayer = try AVAudioPlayer(contentsOfURL:self.audioURL, fileTypeHint:nil)
//            self.audioPlayer.prepareToPlay()
//            self.audioPlayer.play()
//        }catch {
//            print("Error getting the audio file")
//        }
//        
 //   }
    

    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentCourse.contents.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        if indexPath.row<self.currentCourse.contents.count && self.currentCourse.contents[indexPath.row].getType()==COURSE_ITEM_TYPE_AUDIOTEXT {
            let cell = tableView.dequeueReusableCellWithIdentifier("ATItemCell", forIndexPath: indexPath) as! ATItemCell
            let dic = self.currentCourse.contents[indexPath.row].content as! [String:String]
            cell.transcript.text = dic[COURSE_ITEM_TEXT]
            cell.audioUrl = NSURL(fileURLWithPath: dic[COURSE_ITEM_AUDIO]!)
            return cell

        }
        if indexPath.row<self.currentCourse.contents.count && self.currentCourse.contents[indexPath.row].getType()==COURSE_ITEM_TYPE_IMAGE {
            
            let cell2 = tableView.dequeueReusableCellWithIdentifier("ImageItemCell", forIndexPath: indexPath) as! ImageItemCell
            let dic = self.currentCourse.contents[indexPath.row].content as! [String:String]
            
            if let stringUrl = dic[COURSE_ITEM_IMAGE] {
                if let url = NSURL(string: stringUrl) {
                    if let data = NSData(contentsOfURL: url) {
                        cell2.imageView?.image = UIImage(data: data)
                    }
                }
            }
            return cell2
        }
        
        //if indexPath.row==self.currentCourse.contents.count+1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("CreateCourseItemCell", forIndexPath: indexPath) as! CreateCourseItemCell
            
            
            return cell
        //}
        
                
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            self.currentCourse.deleteCourseItem(indexPath.row+1)
        }
    }
    
    
    //Long-press reordering can be disabled entirely by setting a Bool to lprTableView.longPressReorderEnabled
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.currentCourse.moveItemTo(sourceIndexPath.row+1,to: destinationIndexPath.row+1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backTapped() -> Void {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}