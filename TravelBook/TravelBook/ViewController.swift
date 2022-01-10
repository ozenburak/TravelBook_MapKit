//
//  ViewController.swift
//  TravelBook
//
//  Created by burak ozen on 27.09.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    //    kullanıcının haritada konumunu almak için olusturulması gerekmektedir.
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        //        asagıda kullanıcının konumununun ne kadr keskinlikle bulunacagını yazıyoruz.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //        asagıda kullanıcıdan konumunu ogrenmek için izin alıyoruz. sadece appi kullanırken ya da her zman falan diye seçebiliyoruz aşağıda uygulamayı kullanırken diye seçtik.
        locationManager.requestWhenInUseAuthorization()
        //        diyerek kullanıcının yerini almaya başlıyoruz.
        locationManager.startUpdatingLocation()
        
      
        //        haritada tıklanınca pin çıkması için guesturerecog olusturuyoruz. uzun basınca pinle işlemi için " UILongPressGestureRecognizer " komutu kullanılıyo. ozelliği uzun basınca sagırılacak.
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        //      guncel içeriisnde bulundugu durumu gosterir state
        //        gestureRecognizer.state == .began
        //        asagıda kullanıcının ne kadar sure basılı tutması gerektiğini seçiyoruz genelde 3 secilir.
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedTitle != "" {
            //CoreData
          
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            //            filtre ekliyorum
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        //                        tum bunları if let içerisinde kontrol etmem daha mantıklı olacak cunku ornek oalrak title tutmadı subtitlea bak o da olmazsa digerine baka gibi
                        
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        //                                        en son her şeyin oldugundan eminsen annotiation umu olusturabilirim
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                    }
                                }
             
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
            
            
        } else {
            //Add New Data
        }
        
        
    }
    
    //    bu func içeriisinde parantez içinde (gestureRecognizer: UILongPressGestureRecognizer) tanımlarsak func içerisinde ben gestureRecognizer ın yanına nokta koyarım ve tum ozelliklerini kullanırım.
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer) {
        //        adam tıkladıktan sonra tıkladıgı yerin koordinatlarını buliyim ki orayı kayıt ediyim
        if gestureRecognizer.state == .began {
            //            dokunulan noktaları almak geekiyo
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            //            sagıdaki dokunulan koordinatları verecwk
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            //            ve boylece her dokundugumuzda kullanıcnın koordinatları değişicek ve ben SAVE butonuna basınca buton func a gelip orada kayıt edebileceğiz.
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
            
        }
        
    }
    
    //    bu bana guncellenen lokasyonları dizi içerisinde veriyo. neden dizi içerisinde cunku lokasyın genel guncelleniyo hep,
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            //        asagıda konusmlarla çalısırken enlem ve boylam bilgileri kullanılması gerekmekte bu nedenle aşağıdaki objeyi cagırıyoruz ki enlem boylam bilgilerini girebileleim. locations[0].coordinate.latitude yazarak suanki mevcut konumuzu çekerek enlem ve boylamlarını giriyoruz  aynı şekilde.
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            //        birde zoom seviyesi ayarlamamız gerekmekte. asağıdaki objeyle bunu sağlamktayız. değerleri ne kadar ufaksa o kadar zoom
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            //        birde region olusturmamız gerekmekte bunu olustururken kullanılan objede açılan parantezde ilk bölümüne merkezde nerde olsun olanı seçiyoruz. 2. boşluğunda da ne kadar zoomlasın diye sormakta.
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        } else {
            //
        }
    }
    
    //    ANNOTATION  özelleştirme
    //    burada eger bu fonk yazmazsak kenid otomatik annotationını koyuyo ama yazarsak bizden bi tane MKannotation istiyo buna ve bunu döndürücez
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //        burada kullanıcımın yerini göstermek istemiyorum sadece kayıtlı olan yeri tıkladıgımda gostermek için
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //            bir baloncukla birlikte ekstra özellik gösterebildiğimiz bölüm
            pinView?.canShowCallout = true
            //             annotationlar kırmızı çıkıyo genelde ona istediğdin rengi verebiliyosun
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            //            bu buttonu sağ tarafında gosterilecek şekilde göster diye komutu yazıyoruz.
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        
        
        return pinView
    }
    
    //        bu func haritada seçtiğimiz bir mekanın yanında çıkan butona basınca harita uygulamasını kullanabilmek için kullanılan bir func
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            //            koordinatlar ve yerler arasında baglantı kurmamaızı sağlayan bir sınıf. bunun içerisinde bneim gitmek istediğim yeri gösteren bir obje olacak.
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure
                //                closure
                //            yukarıdaki  (placesmarks, error) yazılımının anlamı   bu genelde bi iş yapıyoruz bunun sonucunda bize bişey verecek yani ya hata ya da placemarks gibi bişeyi verecek bize

                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                                      
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        //                        burada da yol tarifi alırken kullanılacak olan yontemi göster olarak kullanılmaktadır.
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                                      
                }
            }
        }
            
            
        }
    
    
    
    
    }
    
    
    


    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
        //        butun appe mesaj gonderip burada bir observer kullanarak ne yaapcagımızı soyluyo
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        //       dersem beni bi önceki VC  a geri gonderir o da listVC
        navigationController?.popViewController(animated: true)
        
        
    }
    
    
    
}

