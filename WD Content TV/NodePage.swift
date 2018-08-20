//
//  NodePage.swift
//  WD Content TV
//
//  Created by Сергей Сейтов on 09.08.2018.
//  Copyright © 2018 V-Channel. All rights reserved.
//

import Foundation

let NODE_PAGE_SIZE = 5

class NodePage {
    
    let size:Int
    var offset:Int
    var nodes:[Node] = []
    
    init(_ fromNodes:[Node]) {
        self.size = fromNodes.count
        self.offset = 0
        for i in 0..<NODE_PAGE_SIZE {
            self.nodes.append(fromNodes[i])
        }
    }
    
    func nodeForIndex(_ index:Int) -> Node {
        return nodes[index]
    }
    
    func moveTo(_ index:Int, offset:Int, fromNodes:[Node]) {
        nodes.removeAll()
        
        self.offset = offset
//        print("move to \(index), offset \(offset) from \(fromNodes.count)")
        var nodeIndex = offset

        for _ in 0..<NODE_PAGE_SIZE {
            self.nodes.append(fromNodes[nodeIndex])
            nodeIndex += 1
            if nodeIndex >= fromNodes.count {
                nodeIndex = 0
            }
        }
    }
    
    func moveTop(_ fromNodes:[Node]) {
        nodes.removeLast()
        if offset > 0 {
            offset = offset - 1
        } else {
            offset = size - 1
        }
//        print("add to Top \(offset)")
        nodes.insert(fromNodes[offset], at: 0)
    }
    
    func moveBottom(_ fromNodes:[Node]) {
        nodes.removeFirst()
        if offset + NODE_PAGE_SIZE >= (size - 1) {
            offset -= (size - 1)
        } else {
            offset += 1
        }
//        print("add to Bottom \(offset + NODE_PAGE_SIZE)")
        nodes.append(fromNodes[offset + NODE_PAGE_SIZE])
    }
}
