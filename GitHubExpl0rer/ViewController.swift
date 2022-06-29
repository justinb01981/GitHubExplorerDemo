import UIKit
import GithubAPI

class GitHubExpl0rerViewController: UIViewController {

    let tableCellId = "ViewCell"
    let viewModel = GitHubExpl0rerViewModel()
    var tableView: UITableView!

    private var maxContentOffset = 0.0
    var doneLoading = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView = UITableView(frame: view.bounds)
        tableView.register(GithubRepsitoryCell.self, forCellReuseIdentifier: tableCellId)
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self

        // kick off initial load
        tableView.contentOffset = CGPoint(x: 0.0, y: 1.0)
        scrollViewDidScroll(tableView)
    }
}

extension GitHubExpl0rerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: tableCellId) as? GithubRepsitoryCell else {
            fatalError("failed to dequeue cell with ID \(tableCellId)")
        }

        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.numberOfLines = 0
        cell.imageView?.image = UIImage(systemName: "star.empty")
        cell.textLabel?.attributedText = NSAttributedString(string: viewModel.results[indexPath.item].full_name)
        cell.setNeedsLayout()
        cell.setNeedsDisplay()

        viewModel.getOrganization(at: indexPath.item, then: {
            result in
            guard let result = result else {
                // reached the end
                self.doneLoading = true
                return
            }

            let attrStr = NSAttributedString(string: "\(result.full_name)\n\(result.html_url)\n\(result.description ?? "")")
            cell.reposURL = URL(string: result.html_url)
            cell.textLabel?.attributedText = attrStr

            if  let avatarStr = result.avatar_url,
                let avatarUrl = URL(string: avatarStr),
                let imgData = try? Data(contentsOf: avatarUrl),
                let img = UIImage(data: imgData) {

                cell.imageView?.image = img
            }
            cell.setNeedsLayout()
            cell.setNeedsDisplay()
        })

        return cell
    }
}

extension GitHubExpl0rerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? GithubRepsitoryCell,
           let cellURL = cell.reposURL {

            UIApplication.shared.openURL(cellURL)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= maxContentOffset && !doneLoading {
            maxContentOffset = scrollView.contentOffset.y

            let nextOffset = viewModel.results.count + 1
            viewModel.getOrganization(at: nextOffset) {
                [weak self] result in
                // load more
                if let org = result {
                    self?.viewModel.results += [org]
                    self?.tableView.reloadData()
                    print("loading more orgs @ offset \(nextOffset)")
                }
            }
        }
    }
}
