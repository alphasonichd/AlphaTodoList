//
//  TodoListViewController.swift
//  AlphaTodoList
//
//  Created by developer on 20.05.21.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    let realm = try! Realm()
    var todoItems: Results<Item>?
    
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let hexColor = selectedCategory?.color,
              let currentCategory = selectedCategory,
              let navBar = navigationController?.navigationBar,
              let navBarColor = UIColor(hexString: hexColor) else {
            fatalError()
        }
        title = currentCategory.name
        navBar.backgroundColor = navBarColor
        navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: ContrastColorOf(navBarColor, returnFlat: true)]
        searchBar.backgroundColor = navBarColor
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add a New Item",
                                      message: "",
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "Add item",
                                   style: .default) { alertAction in
            guard let currentCategory = self.selectedCategory else {
                return
            }
            do {
                try self.realm.write {
                    let newItem = Item()
                    newItem.title = textField.text ?? "No item"
                    newItem.dateCreated = Date()
                    currentCategory.items.append(newItem)
                }
            } catch {
                print("Error writing a new item: \(error)")
            }
            self.tableView.reloadData()
        }
        
        alert.addAction(action)
        alert.addTextField { alertTextField in
            alertTextField.placeholder = "Add a new item..."
            textField = alertTextField
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    override func updateModel(at indexPath: IndexPath) {
        guard let deletingItem = todoItems?[indexPath.row] else {
            return
        }
        
        do {
            try realm.write {
                realm.delete(deletingItem)
            }
        } catch {
            print("Error deleting item: \(error)")
        }
    }
}

//MARK: - Methods

extension TodoListViewController {
    
    private func loadItems() {
        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()
    }
}

//MARK: - Table View Data Source and Delegate Methods

extension TodoListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row], let currentCategory = selectedCategory {
            cell.textLabel?.text = item.title
            cell.accessoryType = item.done ? .checkmark : .none
            if let color = UIColor(hexString: currentCategory.color)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(todoItems?.count ?? 1)) {
                cell.backgroundColor = color
                cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
            }
        } else {
            cell.textLabel?.text = "No items added yet"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = todoItems?[indexPath.row] else {
            return
        }
        do {
            try realm.write {
                item.done = !item.done
            }
        } catch {
                print("Error saving Done status: \(error)")
            }
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

//MARK: - Search Bar Methods

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text ?? "").sorted(byKeyPath: "dateCreated", ascending: true)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
