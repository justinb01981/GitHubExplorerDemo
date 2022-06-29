import Foundation
import GithubAPI

class GitHubExpl0rerViewModel {

    var gitAuth: TokenAuthentication!
    var gitHelper: GithubAPI!
    var results: [GithubOrg] = []

    let baseUrl = "https://github.com/"

    init() {
        gitAuth = TokenAuthentication(token: Bundle.main.infoDictionary!["gitAccessToken"] as! String)
        gitHelper = GithubAPI(authentication: gitAuth)
    }

    func getOrganization(at idx: Int, then thenDo: @escaping (GithubOrg?) -> Void) {

        // serial queue to avoid race conditions
        DispatchQueue(label: "GitHubExpl0rerViewModelSerialQueue").async { [unowned self] in
            // reserve memory for in-flight entries
            let offset = results.count

            let targetResult = results.count

            // just one org added at a time (pageSize=1) for now
            results += [GithubOrg(id: 0, full_name: "Loading...", html_url: "", description: "", avatar_url: "")]

            gitHelper.gh_get(path: "/user/repos?page=\(idx)&per_page=\(1)",
                             parameters: nil, headers: ["Accept": "application/vnd.github.v3+json"]) {
                [weak self] data, response, error in

                DispatchQueue(label: "GitHubExpl0rerViewModelSerialQueue").async { [unowned self] in
                    let organizationDecoder = JSONDecoder()

                    guard let response = response,
                          let data = data,
                          let self = self,
                          error == nil
                    else {
                        fatalError("organizations: failed to retrieve with error \(error)")
                    }

                    do {
                        let resultsParsed = try organizationDecoder.decode([GithubOrg].self, from: data)

                        if resultsParsed.count == 0 {
                            // no more results
                            // remove any results that failed to load
                            if idx < self.results.count ?? 0 {
                                self.results.remove(at: idx)
                            }

                            DispatchQueue.main.async {
                                thenDo(nil)
                            }
                            return
                        }

                        var i = 0
                        for gitRepo in resultsParsed {

                            if targetResult < self.results.count {
                                self.results[targetResult] = gitRepo
                            }

                            // TODO: converting to path by assuming a known base-url and trimming is wrong
//                            self.getRepository(at: gitRepo.html_url.replacingOccurrences(of: self.baseUrl, with: ""))
//
                            i += 1
                        }

                        for org in resultsParsed {
                            DispatchQueue.main.async {
                                thenDo(org)
                            }
                        }
                    }
                    catch(let exc) {
                        print("failed to parse response with exception: \(exc)")
                    }
                }
            }
        }
    }

    func getRepository(at path: String) {
        gitHelper.gh_get(path: path, parameters: nil,
                         headers: ["Accept": "application/vnd.github.v3+json"]) {
            [weak self] data, response, error in

            guard error == nil,
                let reposData = data else {
                print("getRepository \(path) failed")
                return
            }

            print("getRepository \(path) data \(String(bytes: reposData, encoding: .utf8) ?? "")")
        }
    }
}
