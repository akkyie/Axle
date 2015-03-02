//
//  AxleTest.swift
//  AxleTest
//
//  Created by Akio Yasui on 2/9/15.
//
//

import Cocoa
import XCTest

class AxleTest: XCTestCase {

	func makeRandomElements(count: UInt) -> [Double] {
		var elements = [Double]()
		for _ in 0 ..< count {
			elements.append(Double(arc4random_uniform(UINT32_MAX)) / Double(UINT32_MAX))
		}
		return elements
	}

	func makeDiagonalElements(count: UInt) -> [Double] {
		var elements = [Double]()
		for n: UInt in 1 ... count {
			for m: UInt in 1 ... count {
				elements.append(n == m ? 1 : 0)
			}
		}
		return elements
	}

	func testMatrixInitializeWithElements() {
		for n: UInt in 1 ... 10 {
			for m: UInt in 1 ... 10 {
				let elements = makeRandomElements(n * m)
				let matrix = Matrix<Double>(elements, rows: n, columns: m, hint: .None, attribute: .EnableLogging)
				XCTAssertEqual(matrix.rowCount, n, "The number of rows must match")
				XCTAssertEqual(matrix.columnCount, m, "The number of columns must match")
				XCTAssertEqual(matrix.elements, elements, "Elements must match")
			}
		}
	}

	func testMatrixInitializeDiagonal() {
		for i: UInt in 1 ... 10 {
			let elements = makeDiagonalElements(i)
			let matrix = Matrix<Double>(identity: i, attribute: .EnableLogging)
			XCTAssertEqual(matrix.rowCount, i)
			XCTAssertEqual(matrix.columnCount, i)
			XCTAssertEqual(matrix.elements, elements)
		}
	}

	func testMatrixCalculationScale() {
		for m: UInt in 1 ... 10 {
			for n: UInt in 1 ... 10 {
				let scalar = Double(arc4random_uniform(UINT32_MAX)) / Double(UINT32_MAX)
				let elements1 = makeRandomElements(m * n)
				let elements2 = (0 ..< m * n).map({ elements1[Int($0)] * scalar })
				let matrix1 = Matrix<Double>(elements1, rows: m, columns: n)
				let matrix2 = Matrix<Double>(elements2, rows: m, columns: n)
				XCTAssertEqual(matrix1.scale(scalar), matrix2, "Scalar multiplication must be correct")
			}
		}
	}

	func testMatrixCalculationSum() {
		for m: UInt in 1 ... 10 {
			for n: UInt in 1 ... 10 {
				let elements1 = makeRandomElements(m * n)
				let elements2 = makeRandomElements(m * n)
				let elements3 = (0 ..< m * n).map({ elements1[Int($0)] + elements2[Int($0)] })
				let matrix1 = Matrix<Double>(elements1, rows: m, columns: n)
				let matrix2 = Matrix<Double>(elements2, rows: m, columns: n)
				let matrix3 = Matrix<Double>(elements3, rows: m, columns: n)
				XCTAssertEqual(matrix1 + matrix2, matrix3, "Addition must be correct")
			}
		}
	}

	func testMatrixCalculationDifference() {
		for m: UInt in 1 ... 10 {
			for n: UInt in 1 ... 10 {
				let elements1 = makeRandomElements(m * n)
				let elements2 = makeRandomElements(m * n)
				let elements3 = (0 ..< m * n).map({ elements1[Int($0)] - elements2[Int($0)] })
				let matrix1 = Matrix<Double>(elements1, rows: m, columns: n)
				let matrix2 = Matrix<Double>(elements2, rows: m, columns: n)
				let matrix3 = Matrix<Double>(elements3, rows: m, columns: n)
				XCTAssertEqual(matrix1 - matrix2, matrix3, "Difference must be correct")
			}
		}
	}

	func testMatrixCalculationNorm() {
		for m: UInt in 1 ... 10 {
			for n: UInt in 1 ... 10 {
				let elements = makeRandomElements(m * n)
				let matrix = Matrix<Double>(elements, rows: m, columns: n)
				let norm1 = elements.reduce(0.0, combine: { $0 + fabs($1) })
				let norm2 = sqrt(elements.reduce(0.0, combine: { $0 + pow($1, 2) }))
				let normI = elements.reduce(0.0, combine: { max($0, fabs($1)) })
				XCTAssertEqualWithAccuracy(matrix.norm(.L1), norm1, 1e-13, "P-1 norm must be correct")
				XCTAssertEqualWithAccuracy(matrix.norm(.L2), norm2, 1e-13, "P-2 norm must be correct")
				XCTAssertEqualWithAccuracy(matrix.norm(.LInfinity), normI, 1e-13, "P-Infinity norm must be correct")
			}
		}
	}
}
