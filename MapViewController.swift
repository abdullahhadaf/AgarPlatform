//
//  MapViewController.swift
//  AlnahdiAgar
//
//  Created by user228807 on 11/9/22.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
private let addIdentifier = "AddRealesViewController"
private let CategoryIdentifire = "CategoryDCell"
private let RealIdentifire = "RealCell"
private  let defaultValues = UserDefaults.standard
class MapViewController: UIViewController , UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate , MKMapViewDelegate ,UIImagePickerControllerDelegate & UINavigationControllerDelegate ,UITextFieldDelegate {
    
    let Activity = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
    private let mapView : MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    private var collectionViewTop : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let itemSpacing: CGFloat = 9
        let itemsInOneLine: CGFloat = 15
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)
        let width = UIScreen.main.bounds.size.width - itemSpacing * CGFloat(itemsInOneLine)
        layout.itemSize = CGSize(width: floor(width/itemsInOneLine), height: 50)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = itemSpacing
        let table = UICollectionView(frame: .zero, collectionViewLayout: layout)
        table.showsHorizontalScrollIndicator = false
        table.backgroundColor = .clear
        return table
    }()
    private var collectionViewReales : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionHeadersPinToVisibleBounds = true
        let table = UICollectionView(frame: .zero, collectionViewLayout: layout)
        table.transform = CGAffineTransform(scaleX: -1, y: 1)
        table.showsHorizontalScrollIndicator = false
        table.backgroundColor = ViewController.backgroundColor
        return table
    }()
    var postsUi = [PostsUI](){
        didSet {
            DispatchQueue.main.async { [self] in
                collectionViewReales.isHidden = postsUi.isEmpty
            }
        }
    }
    var category = [Category]()
    let networkingManager = NetworkingManager()
    private let textFieldSearch : UITextField = {
        let text = UITextField()
        text.textAlignment = .center
        text.backgroundColor = .white
        text.layer.cornerRadius = 5
        text.layer.borderWidth = 0.5
        text.setDimensions(width:200 , height: 50)
        text.layer.borderColor = UIColor.systemCyan.cgColor
        text.placeholder = "ابحث عن المدينة"
        return text
    }()
    private lazy var buttonSearch: UIButton = createButton(
           title: "بحث",
           backgroundColor: .white,
           borderColor: .SouqColorBlue,
           titleColor: .SouqColorBlue,
           action: #selector(searchAction)
       )
    
    private let satiliteIcon = CustomeImageView(width: 42 ,height: 42,backgroundColor: .white,cornorRadius: 42 / 2,borderWidth: 0.5)
    private let satiliteLabel = LabelU(text: "قمر صناعي", color: .SouqColorBlue, textAlginment: .left, sizeText: 15, textName: fontApp)
    let manger = CLLocationManager()
    let dashView = UIView()
    let viewOne = UIView()
    let realesView = RealesCollectionViewCell()
    var tagItem : String?
    var viewListIcon = UIView()
    private let listIcon = CustomeImageView(
        width: 25,
        height: 25,
        backgroundColor: .white,
        cornorRadius: 30 / 2,
        borderWidth: 0
    )

    private let textList = LabelU(
        text: "القائمة",
        color: .black,
        textAlginment: .center,
        sizeText: 10,
        textName: fontApp
    )
    
    // MARK: - view Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backButtonTitle = "رجوع"
        setupManagers()
         setupUI()
         setupMapView()
         setupGestureRecognizers()
         fetchInitialData()
        setupListIcon()
        setupGestures()
     }

     // MARK: - Private Methods

     private func setupManagers() {
         networkingManager.delegate = self
         manger.delegate = self
         manger.requestWhenInUseAuthorization()
         manger.desiredAccuracy = kCLLocationAccuracyBest
         manger.startUpdatingLocation()
     }

     private func setupUI() {
         view.addSubview(mapView)
         mapView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, width: view.frame.width, height: view.frame.height)
         mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
         
         view.addSubview(viewOne)
         viewOne.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 65)
         
         let stackSearch = UIStackView(arrangedSubviews: [buttonSearch, textFieldSearch])
         stackSearch.axis = .horizontal
         stackSearch.distribution = .fillProportionally
         stackSearch.spacing = 5
         viewOne.addSubview(stackSearch)
         stackSearch.centerXAnchor.constraint(equalTo: viewOne.centerXAnchor).isActive = true
         stackSearch.anchor(top: viewOne.topAnchor, left: viewOne.leftAnchor, right: viewOne.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingRight: 5, height: 40)
         
         mapView.addSubview(collectionViewTop)
         collectionViewTop.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
         collectionViewTop.anchor(top: mapView.topAnchor,left: view.leftAnchor,right: view.rightAnchor,paddingTop: 50,paddingLeft: 0,paddingRight: 0,width: view.frame.size.width , height: 50)
         
         mapView.addSubview(satiliteLabel)
         satiliteLabel.anchor(top: collectionViewTop.bottomAnchor, left: view.leftAnchor, paddingTop: 5, paddingLeft: 10)

         view.addSubview(Activity)
         Activity.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
         Activity.anchor(top: view.topAnchor, paddingTop: 200)
         
         mapView.addSubview(dashView)
         dashView.isHidden = true
         dashView.backgroundColor = .white
         dashView.layer.borderWidth = 0.5
         dashView.layer.borderColor = UIColor.systemGray3.cgColor
         dashView.layer.cornerRadius = 5
         dashView.anchor(left: view.leftAnchor, bottom: mapView.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, height: 130)

         setupDashViewContent()
     }

     private func setupMapView() {
         mapView.delegate = self
         textFieldSearch.delegate = self
         textFieldSearch.returnKeyType = .go
         collectionViewReales.delegate = self
         collectionViewReales.dataSource = self
         collectionViewReales.register(RealesForMapCollectionViewCell.self, forCellWithReuseIdentifier: RealIdentifire)
         collectionViewReales.isHidden = true
     }

     private func setupDashViewContent() {
         let stackTow = UIStackView(arrangedSubviews: [realesView.roomsLabel, realesView.twLabel, realesView.spaceLabel])
         stackTow.spacing = 1
         stackTow.distribution = .fillProportionally
         stackTow.axis = .horizontal
         
         let stack = UIStackView(arrangedSubviews: [realesView.postNameLabel, realesView.priceLabel])
         stack.spacing = 5
         stack.distribution = .fillProportionally
         stack.axis = .vertical
         
         dashView.addSubview(stack)
         stack.anchor(top: dashView.topAnchor, left: dashView.leftAnchor, right: dashView.rightAnchor, paddingTop: 10, paddingRight: 10)
         
         dashView.addSubview(stackTow)
         stackTow.anchor(top: stack.bottomAnchor, right: dashView.rightAnchor, paddingTop: 5, paddingRight: 10, width: 290)
         
         dashView.addSubview(realesView.imagePost)
         realesView.imagePost.anchor(top: dashView.topAnchor, left: dashView.leftAnchor, width: 120, height: 130)
     }

     private func setupGestureRecognizers() {
         let tapStalite = UITapGestureRecognizer(target: self, action: #selector(Stalite(sender:)))
         satiliteLabel.addGestureRecognizer(tapStalite)
         satiliteLabel.isUserInteractionEnabled = true
         
         let tap = UITapGestureRecognizer(target: self, action: #selector(actionMove))
         dashView.addGestureRecognizer(tap)
         dashView.isUserInteractionEnabled = true
     }
     
     private func fetchInitialData() {
         getRealese(usercity: "")
         DispatchQueue.global().async { [self] in
             if isLocationServiceEnabled() {
                 checkAuthorization()
             } else {
                 AlertController.showAlertTwoButton(self, msg: "الرجاء تمكين خدمة الموقع")
             }
         }
         
         
         collectionViewTop.delegate = self
         collectionViewTop.dataSource = self
         collectionViewTop.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: CategoryIdentifire)
         downloadSelectDes {
             self.collectionViewTop.reloadData()
         }
     }
    
    private func setupListIcon() {
        viewListIcon.backgroundColor = ViewController.backgroundColor
        viewListIcon.layer.borderColor = UIColor.systemGray.cgColor
        viewListIcon.layer.borderWidth = 0.2
        viewListIcon.layer.cornerRadius = 25 / 2

        listIcon.image = UIImage(systemName: "list.triangle")?.withTintColor(.SouqColorBlue, renderingMode: .alwaysOriginal)
        view.addSubview(viewListIcon)
        viewListIcon.addSubview(listIcon)
        listIcon.centerX(inView: viewListIcon, topAnchor: viewListIcon.topAnchor, paddingTop: 2)
        
        textList.layer.masksToBounds = true
        viewListIcon.addSubview(textList)
        textList.centerX(inView: viewListIcon, topAnchor: listIcon.bottomAnchor, paddingTop: -10)
        
        viewListIcon.anchor(left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingLeft: 22, paddingBottom: 150, width: 50, height: 50)
    }
    // MARK: - Gestures

    private func setupGestures() {
        let tapMap = UITapGestureRecognizer(target: self, action: #selector(handelHome(sender:)))
        viewListIcon.addGestureRecognizer(tapMap)
        viewListIcon.isUserInteractionEnabled = true
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       // collectionViewTop.frame = viewOne.bounds
    }
    @objc func searchAction(){
        textFieldSearch.resignFirstResponder()
        let textSearch =  textFieldSearch.text!
        if textSearch != "" {
            searchFunc(destination: textSearch)
        }else{
            AlertController.showAlert(self, title: "", message: "الرجاء إدخال المدينة")
        }
        
    }
    var Country = ""
    var City = ""
    var Lat = ""
    var Log = ""
    
    var array : [Any]?
   
    
    @objc func Stalite(sender: UIButton){
        if(mapView.mapType == .satellite){
            mapView.mapType = .standard
        }else{
            mapView.mapType = .satellite
        }
    }
    func removeAnnotations(){
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
    }
    func searchFunc(destination: String){
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(destination) { places, error in
            guard let place = places?.first , error == nil else {
                AlertController.showAlert(self, title: "", message: "لا توجد بيانات للعرض")
                
                return}
            /*
            print("place datiled ..")
            print("place \(place.administrativeArea ?? "no country to display")")
            print(">>>>>>>>>>>>\(place.locality ?? "no city to display")")
            */
            guard let location = place.location else {return}
            self.Country = place.administrativeArea ?? ""
            self.City = place.locality ?? ""
            self.Lat = String(location.coordinate.latitude)
            self.Log = String(location.coordinate.longitude)
            
            self.textFieldSearch.text = ""
            print("this city sreach \(self.City)")
            //  self.mapView.addAnnotation(self.pin)
            if self.City != "" {
                defaultValues.set(self.City, forKey: "usercity")
            }
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            self.mapView.setRegion(region, animated: true)
            
            self.getRealese(usercity: place.locality ?? "")
            self.getMarketing(usercity: place.locality ?? "")
        }
    }
    
    
    
    func isLocationServiceEnabled() -> Bool {
            return CLLocationManager.locationServicesEnabled()
    }
    
    func checkAuthorization(){
        switch manger.authorizationStatus {
        case.notDetermined:
            manger.requestAlwaysAuthorization()
            break
        case .authorizedWhenInUse:
            manger.requestAlwaysAuthorization()
            manger.startUpdatingLocation()
            mapView.showsUserLocation = true
            break
        case .denied:
            AlertController.showAlertTwoButton(self, msg: "يرجى السماح للتطبيق بالوصول إلى موقعك لإظهار العقارات")
            break
        case .restricted:
            AlertController.showAlertTwoButton(self, msg: "الوصول إلى الموقع غير مسموح به")
            break
        default:
            print("default .. ")
            break
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        if locations.first != nil {
            manger.startUpdatingLocation()
            // render(location)
            getLocationFristInfo(location: CLLocation(latitude: locValue.latitude, longitude: locValue.longitude))
        }
        if let location = locations.last {
            zoomToUserLocation(location: location)
       //     getLocationFristInfo(location: CLLocation(latitude: locValue.latitude, longitude: locValue.longitude))
            manger.stopUpdatingLocation()
        }
    }
    
    // update location
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
     //   getLocationFristInfo(location: CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude))
     //   self.Activity.startAnimating()
    }
     
        func getLocationFristInfo(location:CLLocation){
            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(location) { places, error in
                guard let place = places?.first , error == nil else {return}
                self.Country = place.administrativeArea ?? ""
                self.City = place.locality ?? ""
                // place.locality ??
                self.getRealese(usercity:  "")
               // self.getMarketing(usercity: place.locality ?? "")
                // if Marketing change color pin only
                if self.City != "" {
                    defaultValues.set(self.City, forKey: "usercity")
                    self.dashView.isHidden = true
                    let Category = defaultValues.string(forKey: "class_search_id") ?? ""
                    DispatchQueue.main.async { [self] in
                        view.addSubview(collectionViewReales)
                        collectionViewReales.anchor( left: view.leftAnchor,bottom: view.bottomAnchor,right: view.rightAnchor,paddingLeft: 5,paddingBottom: 0,paddingRight: 5,width: view.frame.width,height: 130)
                        self.networkingManager.downloadMainCategory(categoryLink: Int(Category) ?? 0)
                        self.collectionViewReales.reloadData()
                    }
                }
            }
            
        }
    
    // MARK: getLocation
    func getLocationInfo(location:CLLocation,name:String,price:Double,postId:Int,advLicense_nm:String){
        DispatchQueue.main.async {self.removeAnnotations()}
         let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(location) { places, error in
                guard let place = places?.first , error == nil else { return}
                guard let location = place.location else {return}
                let pin = MKPointAnnotation()
                pin.coordinate = location.coordinate
                let id = String(postId)
                pin.title = name
                pin.subtitle = id
                self.mapView.addAnnotation(pin)
                self.Lat = String(location.coordinate.latitude)
                self.Log = String(location.coordinate.longitude)
            }
    }
    //MARK: Slide View - Top To Bottom
    func viewSlideInFromTopToBottom(view: UIView) -> Void {
        let transition:CATransition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromBottom
        let button = UIButton(type: .close)
        view.addSubview(button)
        button.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 5, paddingLeft: 5)
        button.addTarget(self, action: #selector(cancelButtonAction), for: .touchDown)
        view.layer.add(transition, forKey: kCATransition)
        view.anchor(left: self.view.leftAnchor ,bottom: self.view.bottomAnchor , right: self.view.rightAnchor)
    }
    // Cancel Button
    @objc func cancelButtonAction(_ sender: Any) {
       self.viewSlideInFromTopToBottom(view: dashView)
       dashView.isHidden = true
    }
     
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard annotation is MKPointAnnotation else { return nil }
        let identifier = "Annotation"
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.canShowCallout = true
                    annotationView.tintColor = .red
       
        let url = URL(string: "https://24.com.sa/bestblog/resources/views/ios_app/agar/product_id.php?id="+annotation.subtitle!!)
         
        URLSession.shared.dataTask(with: url!) { [self](data , response , error) in
            if error == nil {
                do {
                    let parsedData = try JSONSerialization.jsonObject(with: data! as Data, options: .allowFragments) as! [[String : AnyObject]]
                    DispatchQueue.main.async { [self] in
                        let menuDict = parsedData
                        var price : String?
                        price = "\(menuDict[0]["price"]!)"
                        let id = "\(menuDict[0]["id"]!)"
                        annotationView.canShowCallout = true
                        annotationView.animatesDrop = true
                        annotationView.pinTintColor = .systemRed
                        annotationView.isDraggable = true
                        let string = UILabel()
                        string.textAlignment = .right
                        string.textColor = .red
                        let newStr = String3(str: Double(price!)!)
                        string.text = "\(newStr) ريال"
                        annotationView.detailCalloutAccessoryView = string
                        let tag = annotation.subtitle!!
                        //btn.tag = Int(tag) ?? 0
                        
                        let tapMap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                        annotationView.tag = Int(id)!
                        annotationView.addGestureRecognizer(tapMap)
                        annotationView.isUserInteractionEnabled = true
                        
                    }
                }catch{
                    print("this error >> \(error)")
                }
            }
        }.resume()
                 
                return annotationView
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer){
        let id = gesture.view?.tag ?? 0
        let idString = String(id)
        ShowItem(id: idString)
    }
    
    func ShowItem(id: String){
        let url = URL(string: "https://24.com.sa/bestblog/resources/views/ios_app/agar/product_id.php?id="+id)
        self.dashView.isHidden = false
        self.viewSlideInFromTopToBottom(view: self.dashView)
        self.collectionViewReales.isHidden = true
        guard url != nil else { return }
        URLSession.shared.dataTask(with: url!) { [self](data , response , error) in
            if error == nil {
                do {
                    let parsedData = try JSONSerialization.jsonObject(with: data! as Data, options: .allowFragments) as! [[String : AnyObject]]
                    let menuDict = parsedData
                    DispatchQueue.main.async { [self] in
                        let roomText = "غرف"
                        let twText = "حمام"
                        let m2 = "متر مربع"
                        var rentalText = ""
                        var furnished = ""
                        if( "\(menuDict[0]["furnished"]!)" != "" && "\(menuDict[0]["furnished"]!)" != "<null>"){
                            if  "\(menuDict[0]["furnished"]!)" == "yes" {
                                furnished = "مفروشة"
                            }else{
                                furnished = "بلاطة"
                            }
                        }
                        self.realesView.postNameLabel.text  = "\(menuDict[0]["classification_individual_name"]!) \(furnished)"
                        
                        if( "\(menuDict[0]["Rental_term"]!)" != "" && "\(menuDict[0]["Rental_term"]!)" != "<null>" ){
                            if( "\(menuDict[0]["Rental_term"]!)" == "monthly"){
                                rentalText = "شهري"
                            }else if( "\(menuDict[0]["Rental_term"]!)" == "quarterly"){
                                rentalText = "ربع سنوي"
                            }else if( "\(menuDict[0]["Rental_term"]!)" == "semi-annual"){
                                rentalText = "نصف سنوي"
                            }else if( "\(menuDict[0]["Rental_term"]!)" == "annual"){
                                rentalText = "سنوي"
                            }else if( "\(menuDict[0]["Rental_term"]!)" == "weekly"){
                                rentalText = "اسبوعي"
                            }else{
                                rentalText = "يومي"
                            }
                        }
                        let price = "\(menuDict[0]["price"]!)"
                        let newStr = String3(str: Double(price)!)
                        let sar = " ريال"
                        self.realesView.priceLabel.text = newStr + sar + " " + rentalText
                        
                        if("\(menuDict[0]["rooms"]!)" != "" && "\(menuDict[0]["rooms"]!)" != "<null>"){
                            realesView.roomsLabel.text = "\(menuDict[0]["rooms"]!) \(roomText)"
                        }else{
                            realesView.roomsLabel.isHidden = true
                        }
                        if("\(menuDict[0]["toilets"]!)" != "" && "\(menuDict[0]["toilets"]!)" != "<null>"){
                            realesView.twLabel.text = "\(menuDict[0]["toilets"]!) \(twText)"
                        }else{
                            realesView.twLabel.isHidden = true
                        }
                        if("\(menuDict[0]["space"]!)" != "" && "\(menuDict[0]["space"]!)" != "<null>"){
                            realesView.spaceLabel.text = "\(menuDict[0]["space"]!) \(m2)"
                        }else{
                            realesView.spaceLabel.isHidden = true
                        }
                        if ( "\(menuDict[0]["classification_id"]!)" == "2" || "\(menuDict[0]["classification_id"]!)" == "15" || "\(menuDict[0]["image1"]!)" == "noimage/noimage.png"){
                            realesView.imagePost.isHidden = true
                        }else{
                            realesView.imagePost.isHidden = false
                        }
                       
                    }
                        let imgPost = "\(menuDict[0]["image1"]!)"
                        if (imgPost != "" && imgPost != "<null>"){
                            let urlString = "https://agar.24.com.sa/images/imagesPosts/"+(imgPost)
                            if let url = URL(string: urlString) {
                                URLSession.shared.dataTask(with: url) { (data, response, error) in
                                    // Error handling...
                                    guard let imageData = data else { return }
                                    DispatchQueue.main.async {
                                        self.realesView.imagePost.image = UIImage(data: imageData)
                                    }
                                }.resume()
                            }
                        }
                    tagItem = id
                        
                    
                }catch{
                    print("this error >>> \(error)")
                }
            }
        }.resume()
    }
  
         
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       // self.tabBarController?.tabBar.isHidden = true
        //self.tabBarController?.tabBar.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @objc func actionMove(sender : UIButton){
            guard tagItem != nil else { return }
            let url = URL(string: "https://24.com.sa/GitProductForAppIos/"+tagItem!)
        guard url != nil else { return }
        AF.request(url!, method: .get, parameters: nil).responseData
               {
                   response in
                   switch response.result {
                   case .success(let data):
                       do {
                           let user = try JSONSerialization.jsonObject(with: data)
                           let id = (user as AnyObject).value(forKey: "id") as! Int
                           let idU = (user as AnyObject).value(forKey: "idU") as! String
                           let email = (user as AnyObject).value(forKey: "email") as! String
                           let image1 = (user as AnyObject).value(forKey: "image1") as? String   ?? ""
                           let video = (user as AnyObject).value(forKey: "video") as? String ?? ""
                           let advertising_license = (user as AnyObject).value(forKey: "advertising_license") as? String ?? ""
                           let active = (user as AnyObject).value(forKey: "active") as! String
                           let lat = (user as AnyObject).value(forKey: "lat") as! String
                           let lng = (user as AnyObject).value(forKey: "lng") as! String
                            let nextVC = Show2ViewController()
                            nextVC.postId = String(id)
                            nextVC.idU =  idU
                            nextVC.email =  email
                            nextVC.image1 = image1
                            nextVC.video = video
                            nextVC.advertising_license = advertising_license
                            nextVC.activePost = active
                            nextVC.lat = Double(lat)
                            nextVC.lng = Double(lng)
                           let navController = UINavigationController(rootViewController: nextVC)
                           self.present(navController, animated: true, completion: nil)
                    }catch {
                        print("this error action move >> \(error)")
                    }
                   case .failure(let error):
                       print(error)
                       break
                   }
            }.resume()
        }
        // MARK: Get Realese
        
        func getRealese(usercity:String){
            let classifi = defaultValues.string(forKey: "class_search") ?? ""
            let urluser = ( "https://24.com.sa/bestblog/resources/views/ios_app/agar/products.php?classification="+classifi+"&city="+usercity+"&price_max=&price_min=&neighborhood=")
                let urlString = urluser.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let url = URL(string: urlString!)
                guard url != nil else { return }
            URLSession.shared.dataTask(with: url!) {(data , response , error) in
                if error == nil {
                    do {
                        let parsedData = try JSONSerialization.jsonObject(with: data! as Data, options: .allowFragments) as! [[String : AnyObject]]
                        self.array = parsedData
                        guard let menuDict = parsedData as? [[String: AnyObject]] else { return }
                        for i in 0..<menuDict.count {
                            let latitude = menuDict[i]["lat"]
                            let longitude = menuDict[i]["lng"]
                            let name = menuDict[i]["classification_individual_name"]
                            let price = menuDict[i]["price"]
                            let id = menuDict[i]["id"]
                            let advertising_license = menuDict[i]["advertising_license"]
                          //  let brokerage_and_marketing_license_number = menuDict[i]["brokerage_and_marketing_license_number"]
                            let latNumber = Double(latitude as! Substring) ?? 0.0
                            let longNumber = Double(longitude as! Substring) ?? 0.0
                            let priceNumber = Double(price as! Substring) ?? 0.0
                            let idNumber = Int(id as! Substring) ?? 0
                            self.getLocationInfo(location:CLLocation(latitude: latNumber , longitude: longNumber ),name: name as! String,price:priceNumber ,postId:idNumber,advLicense_nm:advertising_license as? String ?? "")
                        }
                         
                    }catch {
                        print("this error >>>>>>>>>>>>>>> map view \(error)")
                    }
                }
                DispatchQueue.main.async {
                    self.Activity.stopAnimating()
                }
            }.resume()
        }
    func getMarketing(usercity:String){
        let urluser = ( "https://24.com.sa/bestblog/resources/views/ios_app/agar/marketing_request.php?city="+usercity)
            let urlString = urluser.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            let url = URL(string: urlString!)
        guard url != nil else { return }
        URLSession.shared.dataTask(with: url!) {(data , response , error) in
            if error == nil {
                do {
                    let parsedData = try JSONSerialization.jsonObject(with: data! as Data, options: .allowFragments) as! [[String : AnyObject]]
                    self.array = parsedData
                    guard let menuDict = parsedData as? [[String: AnyObject]] else { return }
                    for i in 0..<menuDict.count {
                        let latitude = menuDict[i]["lat"]
                        let longitude = menuDict[i]["lng"]
                        let name = "طلب تسويق"
                        let price = menuDict[i]["price"]
                        let id = menuDict[i]["id"]
                        let advertising_license = menuDict[i]["advertising_license"]
                     //   let brokerage_and_marketing_license_number = menuDict[i]["brokerage_and_marketing_license_number"]
                        let latNumber = Double(latitude as! Substring) ?? 0.0
                        let longNumber = Double(longitude as! Substring) ?? 0.0
                        let priceNumber = Double(price as! Substring) ?? 0.0
                        let idNumber = Int(id as! Substring) ?? 0
                        self.getLocationInfo(location:CLLocation(latitude: latNumber , longitude: longNumber ),name: name ,price:priceNumber ,postId:idNumber,advLicense_nm:advertising_license as? String ?? "")
                        
                    }
                }catch {
                    print("this error >>>>>>>>>>>>>>> map view marketing \(error)")
                }
            }
            DispatchQueue.main.async {
                self.Activity.stopAnimating()
            }
        }.resume()
    }
    
        func zoomToUserLocation(location: CLLocation){
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters:10000,
                                            longitudinalMeters:10000)
            mapView.setRegion(region, animated: true)
        }
    
    // When touching the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFieldSearch.resignFirstResponder()
    }
     
       private func createButton(title: String, backgroundColor: UIColor, borderColor: UIColor, titleColor: UIColor, action: Selector) -> UIButton {
           let button = UIButton()
           button.layer.borderColor = borderColor.cgColor
           button.layer.borderWidth = 0.5
           button.setTitleColor(titleColor, for: .normal)
           button.setTitle(title, for: .normal)
           button.backgroundColor = backgroundColor
           button.setDimensions(width: 100, height: 45)
           button.layer.cornerRadius = 5
           button.addTarget(self, action: action, for: .touchUpInside)
           return button
       }
    
    }
extension MapViewController: UICollectionViewDelegateFlowLayout  {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == collectionViewTop {
            return category.count
        }else{
            return postsUi.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collectionViewTop {
            return CGSize(width: 150 , height: 100/2)
        }else{
            let width = view.frame.width
            return CGSize(width: width , height: 130)
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == collectionViewTop {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryIdentifire, for: indexPath) as! CategoryCollectionViewCell
            cell.category = category[indexPath.row]
          //  cell.transform = CGAffineTransform(scaleX: -1, y: 1)
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RealIdentifire, for: indexPath) as! RealesForMapCollectionViewCell
            cell.posts = postsUi[indexPath.row]
            cell.transform = CGAffineTransform(scaleX: -1, y: 1)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == collectionViewTop {
            self.Activity.startAnimating()
            let city = "" //defaultValues.string(forKey: "usercity") ?? ""
            defaultValues.set(category[indexPath.row].name, forKey: "class_search")
            defaultValues.set(category[indexPath.row].id, forKey: "class_search_id")
            defaultValues.set("", forKey: "usercity")
            self.getRealese(usercity: city)
            DispatchQueue.main.async { [self] in
                self.networkingManager.downloadMainCategory(categoryLink: category[indexPath.row].id)
                self.collectionViewReales.reloadData()
            }
        }else{
            DispatchQueue.main.async { [self] in
            let nextVC = Show2ViewController()
            nextVC.postId = postsUi[indexPath.row].id
            nextVC.idU = postsUi[indexPath.row].idU
            nextVC.email = postsUi[indexPath.row].email
            nextVC.lat = Double(postsUi[indexPath.row].lat)
            nextVC.lng = Double(postsUi[indexPath.row].lng)
            nextVC.image1 = postsUi[indexPath.row].image1
            nextVC.video = postsUi[indexPath.row].video
            nextVC.advertising_license = postsUi[indexPath.row].advertising_license
            nextVC.activePost = postsUi[indexPath.row].active
          // self.navigationController?.pushViewController(nextVC, animated: true)
          let navController = UINavigationController(rootViewController: nextVC)
          self.present(navController, animated: true, completion: nil)
        }
        }
    }
    func downloadSelectDes(completed: @escaping() -> ()){
       
        let url = URL(string: "https://24.com.sa/bestblog/resources/views/ios_app/agar/Category.php")
        URLSession.shared.dataTask(with: url!) {(data , response , error) in
           
            if error == nil {
                do {
                    self.category = try JSONDecoder().decode([Category].self, from: data!)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        completed()
                        if self.category.isEmpty{
                            print("helooooooooo")
                        }else{
                            print("looooooo")
                        }
                    }
                }catch {
                    print(error)
                }
            }
        }.resume()
    }
    }

extension MapViewController : NetworkingManagerDelegate  {
    
    func mainCategoriesHasDownloaded(mainCategories: [PostsUI]) {
        self.postsUi =  mainCategories
        DispatchQueue.main.async {
            self.collectionViewReales.reloadData()
        }
        
        if mainCategories.isEmpty {
            self.removeAnnotations()
        }
    }
   
}
