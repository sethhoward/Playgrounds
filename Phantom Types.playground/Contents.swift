//: Playground - noun: a place where people can play

import UIKit

class MyDataSource: NSObject, UITableViewDataSource {
    var whoAmI: String = ""
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
}

struct DataSource<A> {
    let dataSource: MyDataSource
}

enum Providers {}
enum Physicians {}

func dataSourceForProviders() -> DataSource<Providers> {
    let dataSource = MyDataSource()
    dataSource.whoAmI = "provider"
    
    return DataSource<Providers>(dataSource: dataSource)
}


func dataSourceForPhysicians() -> DataSource<Physicians> {
    let dataSource = MyDataSource()
    dataSource.whoAmI = "Physicians"
    
    return DataSource<Physicians>(dataSource: dataSource)
}

func handleSomethingForProvider(dataSource: DataSource<Providers>) {
    dataSource.dataSource.whoAmI
}


let dsProvider = dataSourceForProviders()
let dsPhysician = dataSourceForPhysicians()

handleSomethingForProvider(dsProvider)
//handleSomethingForProvider(dsPhysician)   // will not compile



struct Alcohol<A> {
    let identifier: String
}

enum Beer {}
enum Spirit {}

func beerAndChaser(beer: Alcohol<Beer>, shot: Alcohol<Spirit>) {
    beer.identifier
    shot.identifier
}

let beer = Alcohol<Beer>(identifier: "Lone Star")
let spirit = Alcohol<Spirit>(identifier: "Bourbon")
// let texas2Step = beerAndChaser(spirit, shot: beer) // will not compile

