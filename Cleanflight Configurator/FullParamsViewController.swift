//
//  FullParamsViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class FullParamsViewController: UITableViewController, UseMAVLinkVehicle, UISearchResultsUpdating {
    private let OtherSection = "Other"
    
    private var detailedRow: NSIndexPath?

    private var sections = [String : [String]]()
    private var sortedSections = [String]()
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredParamIds = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Search bar
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !mavlinkVehicle.parametersLoaded {
            refreshAction(self)
        }
    }
    
    private var searchActive: Bool {
        return searchController.active && searchController.searchBar.text != ""
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if searchActive {
            return 1
        } else {
            return sortedSections.count
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchActive {
            return ""
        } else {
            return sortedSections[section]
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            if section == 0 {
                return filteredParamIds.count
            } else {
                return 0
            }
        } else {
            return sections[sortedSections[section]]?.count ?? 0
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == detailedRow {
            return 116
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(indexPath == detailedRow ? "detailedParamTableCell" : "paramTableCell", forIndexPath: indexPath) as! ParamTableCell

        let paramId: String
        if searchActive {
            paramId = filteredParamIds[indexPath.row]
        } else {
            paramId = sections[sortedSections[indexPath.section]]![indexPath.row]
        }
        cell.initCell(paramId)

        return cell
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        var indexPaths = [NSIndexPath]()
        if detailedRow != nil {
            indexPaths.append(detailedRow!)
        }
        if detailedRow == indexPath {
            detailedRow = nil
        } else {
            detailedRow = indexPath
            indexPaths.append(indexPath)
        }
        tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearch(searchController.searchBar.text!)
    }
    
    // MARK:
    
    func filterContentForSearch(searchText: String) {
        detailedRow = nil
        if !searchText.isEmpty {
            let searchString = searchText.lowercaseString
            filteredParamIds = mavlinkVehicle.parametersById.keys.filter { paramId in
                if paramId.lowercaseString.containsString(searchString) {
                    return true
                }
                guard let param = ParameterList.instance.getParameter(paramId) else {
                    return false
                }
                if param.description != nil && param.description!.lowercaseString.containsString(searchString) {
                    return true
                }
                return param.name.lowercaseString.containsString(searchString)
            }
        }
        tableView.reloadData()
    }
    
    @IBAction func refreshAction(sender: AnyObject) {
        SVProgressHUD.showProgress(0, status: "Loading parameters...", maskType: .Black)
        mavlinkProtocolHandler.requestAllParameters() { progress in
            if progress == 100 {
                self.sections.removeAll()
                for paramId in self.mavlinkVehicle.parametersById.keys {
                    let section: String
                    if let underscore = paramId.rangeOfString("_") {
                        section = paramId.substringToIndex(underscore.startIndex)
                    } else {
                        section = self.OtherSection
                    }
                    if self.sections.keys.contains(section) {
                        self.sections[section]!.append(paramId)
                    } else {
                        self.sections[section] = [ paramId ]
                    }
                }
                self.sortedSections = self.sections.keys.filter({ $0 != self.OtherSection }).sort()
                self.sortedSections.append(self.OtherSection)
                for section in self.sections.keys {
                    self.sections[section] = self.sections[section]!.sort()
                }
                
                self.tableView.reloadData()
                
                SVProgressHUD.dismiss()
            } else {
                SVProgressHUD.showProgress(Float(progress) / 100, status: "Loading parameters...", maskType: .Black)
            }
        }
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        var dirtyParams = [MAVLinkParameter]()
        for param in mavlinkVehicle.parametersById.values {
            if param.dirty {
                dirtyParams.append(param)
            }
        }
        if dirtyParams.isEmpty {
            SVProgressHUD.showInfoWithStatus("Nothing to save")
            return
        }
        SVProgressHUD.showProgress(0, status: "Saving parameters...", maskType: .Black)
        var successCount = 0
        for param in dirtyParams {
            mavlinkProtocolHandler.setParameter(param, callback: { success in
                if success {
                    if successCount != -1 {
                        successCount++
                        SVProgressHUD.showProgress(Float(successCount) / Float(dirtyParams.count), status: "Saving parameters...", maskType: .Black)
                        if successCount == dirtyParams.count {
                            SVProgressHUD.dismiss()
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    successCount = -1
                    SVProgressHUD.showErrorWithStatus("Save failed")
                    self.tableView.reloadData()
                }
            })
        }
    }
}

class ParamTableCell : UITableViewCell, UseMAVLinkVehicle {
    let dirtyColor = UIColor(colorLiteralRed: 164.0 / 255, green: 205.0 / 255, blue: 1, alpha: 1)
    
    @IBOutlet weak var propertyNameLabel: UILabel!
    @IBOutlet weak var numberValueField: NumberField!
    @IBOutlet weak var pickerValueField: UITextField!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var unitLabel: UILabel!
    @IBOutlet weak var descriptionBottom: NSLayoutConstraint!

    var valuePicker: MyDownPicker!
    
    private var paramId: String!
    
    func initCell(paramId: String) {
        if valuePicker == nil {
            valuePicker = MyDownPicker(textField: pickerValueField)
            valuePicker.setPlaceholder("")
            valuePicker.addTarget(self, action: "pickerChanged:", forControlEvents: .ValueChanged)
            numberValueField.addTarget(self, action: "numberFieldChanged:", forControlEvents: .EditingDidEnd)
        }
        self.paramId = paramId

        // Reset and hide both input controls
        numberValueField.value = 0
        valuePicker!.text = nil
        pickerValueField.hidden = true
        numberValueField.hidden = true
        
        propertyNameLabel.text = paramId
        descriptionLabel?.text = ""
        unitLabel?.text = ""
        dirty = false

        guard let mavlinkParam = mavlinkVehicle.parametersById[paramId] else {
            // Can happen during a refresh
            if let parameterMetadata = ParameterList.instance.getParameter(paramId) {
                propertyNameLabel.text = parameterMetadata.name
            }
            return
        }
        
        dirty = mavlinkParam.dirty
        
        if let parameterMetadata = ParameterList.instance.getParameter(paramId) {
            propertyNameLabel.text = parameterMetadata.name
            if parameterMetadata.description != nil {
                descriptionLabel?.text = paramId + ": " + parameterMetadata.description!
            }
            unitLabel?.text = parameterMetadata.unit
            
            if parameterMetadata.values != nil {
                // Value picker
                var labels = [String]()
                var i = 0
                var selectedIndex = -1
                for (v, label) in parameterMetadata.values! {
                    labels.append(label)
                    if Float(v) == Float(mavlinkParam.value) {
                        selectedIndex = i
                    }
                    i++
                }
                if selectedIndex != -1 {
                    valuePicker!.setData(labels)
                    valuePicker!.selectedIndex = selectedIndex
                    pickerValueField.hidden = false
                    
                    return
                } else {
                    NSLog("%@: Value %f not found in list of values %@", paramId, mavlinkParam.value, parameterMetadata.values!.debugDescription)
                    // Treat as a number value
                }
            }
            
            // Number value
            numberValueField.increment = parameterMetadata.increment ?? mavlinkParam.intrisicIncrement
            numberValueField.suggestedMinimum = parameterMetadata.min
            numberValueField.suggestedMaximum = parameterMetadata.max
        } else {
            numberValueField.increment = mavlinkParam.intrisicIncrement
            numberValueField.suggestedMinimum = nil
            numberValueField.suggestedMaximum = nil
        }
        numberValueField.minimumValue = mavlinkParam.intrisicMinimum
        numberValueField.maximumValue = mavlinkParam.intrisicMaximum
        if numberValueField.increment == 0 {
            numberValueField.decimalDigits = 10
        } else {
            numberValueField.decimalDigits = Int(ceil(max(0, -log10(numberValueField.increment))))
        }
        
        numberValueField.hidden = false
        numberValueField.value = mavlinkParam.value
    }
    
    private var dirty = false {
        didSet {
            backgroundColor = dirty ? dirtyColor : UIColor.whiteColor()
        }
    }
    
    @objc
    private func pickerChanged(sender: AnyObject) {
        if valuePicker.selectedIndex != -1 {
            let param = mavlinkVehicle.parametersById[paramId]!
            param.value = ParameterList.instance.getParameter(paramId)!.values![valuePicker.selectedIndex].value
            dirty = param.dirty
        }
    }
    
    @objc
    private func numberFieldChanged(sender: AnyObject) {
        let param = mavlinkVehicle.parametersById[paramId]!
        param.value = numberValueField.value
        dirty = param.dirty
    }
}
