import AWSAuthCore
import AWSAuthUI
import CoreData
import UIKit

class InstanceTableViewController: UITableViewController {
    
    let apiGateway = ApiGateway()
    var instances = [Instance]()
    
    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LocalDataStore")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Error loading persistent container: \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveCoreData() {
        let context = persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "LocalDataStore", in: context)
        for instance in instances {
            let newCoreDataItem = NSManagedObject(entity: entity!, insertInto: context)
            newCoreDataItem.setValue(instance.instanceId, forKey: "instanceId")
            newCoreDataItem.setValue(instance.instanceType, forKey: "instanceType")
            newCoreDataItem.setValue(instance.state, forKey: "state")
            newCoreDataItem.setValue(instance.name, forKey: "name")
        }
        do {
            try context.save()
            print("CoreData saved: \(instances.count)")
        } catch let err as NSError {
            print("CoreData save failed", err)
        }
    }
    
    func flushCoreData() {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocalDataStore")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            print("CoreData flushed")
        } catch {
            print("CoreData flush failed")
        }
    }
    
    func loadCoreData() {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LocalDataStore")
        do {
            let coreDataItems = try context.fetch(fetchRequest)
            let tempInstances = fromNSManagedObjectToInstanceArray(coreDataItems)
            instances = tempInstances.sorted(by: { $0.instanceId > $1.instanceId })
            refreshTable()
            print("CoreData loaded: \(coreDataItems.count)")
        } catch let err as NSError {
            print("CoreData load failed", err)
        }
    }
    
    func fromNSManagedObjectToInstanceArray(_ objects: [NSManagedObject]) -> [Instance] {
        var instances = [Instance]()
        for object in objects {
            let instance = Instance()
            instance?.instanceId = (object.value(forKey: "instanceId")! as! String)
            instance?.instanceType = (object.value(forKey: "instanceType") as! String)
            instance?.name = (object.value(forKey: "name") as! String)
            instance?.state = (object.value(forKey: "state") as! String)
            instances.append(instance!)
        }
        return instances
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForInstanceListUpdatedNotification()
        registerForInstanceStateChangedNotification()
        requestInitialTableLoad()
        enableTableRefresh()
        loadCoreData()
    }
    
    func registerForInstanceListUpdatedNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(instanceListUpdated), name: Notification.Name("InstanceListUpdated"), object: nil)
    }
    
    func registerForInstanceStateChangedNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(instanceStateChanged), name: Notification.Name("InstanceStateChanged"), object: nil)
    }
    
    func requestInitialTableLoad() {
        apiGateway.authenticate()
        apiGateway.invokeGetInstancesApi()
    }
    
    func enableTableRefresh() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(refreshInstanceList), for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    // handle notification
    @objc func instanceListUpdated(notification: Notification) {
        refreshData(notification)
        refreshTable()
    }
    
    // handle notification
    @objc func instanceStateChanged(notification: Notification) {
        apiGateway.invokeGetInstancesApi()
    }
    
    func refreshData(_ notification: Notification) {
        let notificationData = notification.userInfo
        let tempInstances = notificationData!["instances"] as! [Instance]
        print("New data received: \(tempInstances.count)")
        instances = tempInstances.sorted(by: { $0.instanceId > $1.instanceId })
        flushCoreData()
        saveCoreData()
    }
    
    func refreshTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // handle table refresh (pull down)
    @objc func refreshInstanceList() {
        apiGateway.invokeGetInstancesApi()
        refreshControl?.endRefreshing()
    }
    
    // set number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // set number of cells
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instances.count
    }
    
    // populate cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier")
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellIdentifier")
        }
        
        cell!.selectionStyle = UITableViewCell.SelectionStyle.default
        cell!.textLabel!.text = instances[indexPath.row].instanceId
        cell!.detailTextLabel!.text = "\(instances[indexPath.row].name!) - \(instances[indexPath.row].instanceType!) - \(instances[indexPath.row].state!)"
        if (instances[indexPath.row].state == "terminated") {
            cell!.textLabel?.textColor = UIColor.lightGray
            cell!.detailTextLabel?.textColor = UIColor.lightGray
        }
        
        return cell!
    }
    
    // handle cell touch
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let instanceId = instances[indexPath.row].instanceId
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if(instances[indexPath.row].state == "stopped") {
            let startAction: UIAlertAction = UIAlertAction(title: "Start", style: .default) { action -> Void in
                print("starting")
                self.apiGateway.invokeChangeInstanceStateApi(instanceId: instanceId!, action: "start")
                tableView.deselectRow(at: indexPath, animated: true)
            }
            actionSheetController.addAction(startAction)
        }
        
        if(instances[indexPath.row].state == "running") {
            let rebootAction: UIAlertAction = UIAlertAction(title: "Reboot", style: .default) { action -> Void in
                print("rebooting")
                self.apiGateway.invokeChangeInstanceStateApi(instanceId: instanceId!, action: "reboot")
                tableView.deselectRow(at: indexPath, animated: true)
            }
            let stopAction: UIAlertAction = UIAlertAction(title: "Stop", style: .default) { action -> Void in
                print("stopping")
                self.apiGateway.invokeChangeInstanceStateApi(instanceId: instanceId!, action: "stop")
                tableView.deselectRow(at: indexPath, animated: true)
            }
            let updateDnsAction: UIAlertAction = UIAlertAction(title: "Update DNS", style: .default) { action -> Void in
                print("updating dns")
                self.apiGateway.invokeChangeInstanceStateApi(instanceId: instanceId!, action: "update-dns")
                tableView.deselectRow(at: indexPath, animated: true)
            }
            actionSheetController.addAction(updateDnsAction)
            actionSheetController.addAction(stopAction)
            actionSheetController.addAction(rebootAction)
        }
        
        if(["running", "stopped"].contains(instances[indexPath.row].state)) {
            let terminateAction: UIAlertAction = UIAlertAction(title: "Terminate", style: .destructive) { action -> Void in
                let alertController = UIAlertController(title: "\(self.instances[indexPath.row].name!)",
                    message: "Terminate instance \(self.instances[indexPath.row].instanceId!)?", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .destructive, handler: {(action: UIAlertAction!) in
                    print("terminating")
                    self.apiGateway.invokeChangeInstanceStateApi(instanceId: instanceId!, action: "terminate")
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(action: UIAlertAction!) in
                    print("not terminating")
                })
                alertController.addAction(okAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                })
            }
            actionSheetController.addAction(terminateAction)
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            tableView.deselectRow(at: indexPath, animated: true)
        }
        actionSheetController.addAction(cancelAction)
        
        actionSheetController.popoverPresentationController?.sourceView = tableView
        
        present(actionSheetController, animated: true) {
            print(self.tableView.cellForRow(at: indexPath)?.textLabel?.text ?? "")
        }
    }
}
