//
//  CPOpenCV.swift
//  CPOpenCV
//
//  Created by Pai Peng on 26.09.24.
//

import Foundation
//import "CPOpenCV-Bridging-Header.h"


class CPOpenCV {
    init() {
        
    }
    
    func getVersion() ->String {
        return String(cString: getOpenCVVersion())
    }
}
