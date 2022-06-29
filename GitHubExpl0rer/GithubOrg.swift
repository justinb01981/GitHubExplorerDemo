//
//  GithubOrg.swift
//  Pods
//
//  Created by Justin Brady on 6/24/22.
//

import Foundation

struct GithubOrg: Codable {
    var `id`: Int
    var full_name: String
//    var login: String
    var html_url: String
//    var repos_url: String
    var description: String?
    var avatar_url: String?
//    var node_id: String
}
