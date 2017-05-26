import UIKit
import CoreLocation
import MapKit
import AVFoundation
import MediaPlayer
import CoreMotion


class ViewController: UIViewController {
    //MARK: Properties
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var log: UITextView!
    @IBOutlet var clearButton: UIButton!
    
    fileprivate var locations = [MKPointAnnotation]()
    var locationManager: CLLocationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        locationManager.stopUpdatingLocation()
        //locationManager.distanceFilter = 5
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.startDeviceMotionUpdates()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    private var counter: Int = 0
   
    //MARK: Actions
    @IBAction func enableChanged(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startUpdatingLocation()
            clearButton.isEnabled = false
        } else {
            locationManager.stopUpdatingLocation()
            clearButton.isEnabled = true
        }
    }
    @IBAction func clear(_ sender: UIButton) {
        log.text = ""
        mapView.removeAnnotations(mapView.annotations)
        locations.removeAll()
    }
}

extension String {
    /**
     Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
     
     - Parameter length: A `String`.
     - Parameter trailing: A `String` that will be appended after the truncation.
     
     - Returns: A `String` object.
     */
    func truncate(length: Int, trailing: String = "…") -> String {
        if self.characters.count > length {
            return String(self.characters.prefix(length)) + trailing
        } else {
            return self
        }
    }
}


// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else {
            print("Guard")
            return
        }
        
        // Add another annotation to the map
        let annotation = MKPointAnnotation()
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        
        annotation.title = formatter.string(from: date)
        annotation.coordinate = mostRecentLocation.coordinate
        
        // Also add to our map so we can remove old values later
        self.locations.append(annotation)
        
        // Remove values if the array is too big
        while locations.count > 1000 {
            let annotationToRemove = self.locations.first!
            self.locations.remove(at: 0)
            
            // Also remove from the map
            mapView.removeAnnotation(annotationToRemove)
        }
        
        let dm = self.motionManager.deviceMotion?.userAcceleration ?? CMAcceleration(x: 0, y: 0, z: 0)

        let isForeground = UIApplication.shared.applicationState == .active
        
        var textToAppend = String(format: "%@ @ %@ with %f\n", isForeground ? "fg" : "bg", mostRecentLocation, dm.x)
        textToAppend = textToAppend + self.log.text.truncate(length: 1024, trailing: "...")
        self.log.text = textToAppend
        
        mapView.showAnnotations(self.locations, animated: isForeground)
        
        print(String(format: "%@ @ %@ with %f\n", isForeground ? "fg" : "bg", mostRecentLocation, dm.x))
        
        if self.locations.count % 30 == 0 && !isForeground{
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
    }
}
