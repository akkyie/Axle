//
//  Axle.swift
//  Axle
//
//  Created by Akio Yasui on 2/9/15.
//
//

import Foundation
import Swift
import Accelerate

enum Hint {
	case None;
	case ShapeDiagonal;
	case ShapeLowerTriangular;
	case ShapeUpperTriangular;
	case FeatureSymmetric;
	case FeaturePositiveDefinite;
	case FeatureDiagonallyDominant;

	private var _rawValue: la_hint_t {
		var value: UInt32 {
			switch self {
			case .None:                      return LA_NO_HINT
			case .ShapeDiagonal:             return LA_SHAPE_DIAGONAL
			case .ShapeLowerTriangular:      return LA_SHAPE_LOWER_TRIANGULAR
			case .ShapeUpperTriangular:      return LA_SHAPE_UPPER_TRIANGULAR
			case .FeatureSymmetric:          return LA_FEATURE_SYMMETRIC
			case .FeaturePositiveDefinite:   return LA_FEATURE_POSITIVE_DEFINITE
			case .FeatureDiagonallyDominant: return LA_FEATURE_DIAGONALLY_DOMINANT
			}
		}
		return la_hint_t(value)
	}
}

enum Attribute {
	case None;
	case EnableLogging;

	private var _rawValue: la_hint_t {
		var value: UInt32 {
			switch self {
			case .None:          return UInt32(LA_DEFAULT_ATTRIBUTES)
			case .EnableLogging: return LA_ATTRIBUTE_ENABLE_LOGGING
			}
		}
		return la_attribute_t(value)
	}
}

enum Status {
	case Success;
	case PoorlyConditionedWarning;
	case InternalError;
	case InvalidParameterError;
	case DimensionMismatchError;
	case PrecisionMismatchError;
	case SingularError;
	case SliceOutOfBoundsError;

	private var _rawValue: la_hint_t {
		var value: Int32 {
			switch self {
			case .Success:                  return LA_SUCCESS
			case .PoorlyConditionedWarning: return LA_WARNING_POORLY_CONDITIONED
			case .InternalError:            return LA_INTERNAL_ERROR
			case .InvalidParameterError:    return LA_INVALID_PARAMETER_ERROR
			case .DimensionMismatchError:   return LA_DIMENSION_MISMATCH_ERROR
			case .PrecisionMismatchError:   return LA_PRECISION_MISMATCH_ERROR
			case .SingularError:            return LA_SINGULAR_ERROR
			case .SliceOutOfBoundsError:    return LA_SLICE_OUT_OF_BOUNDS_ERROR
			}
		}
		return la_attribute_t(value)
	}

	private init (_ value: la_status_t) {
		var value: Status {
			switch value {
			case Int(LA_SUCCESS):                    return .Success
			case Int(LA_WARNING_POORLY_CONDITIONED): return .PoorlyConditionedWarning
			case Int(LA_INTERNAL_ERROR):             return .InternalError
			case Int(LA_INVALID_PARAMETER_ERROR):    return .InvalidParameterError
			case Int(LA_DIMENSION_MISMATCH_ERROR):   return .DimensionMismatchError
			case Int(LA_PRECISION_MISMATCH_ERROR):   return .PrecisionMismatchError
			case Int(LA_SINGULAR_ERROR):             return .SingularError
			case Int(LA_SLICE_OUT_OF_BOUNDS_ERROR):  return .SliceOutOfBoundsError
			default:                                 return .InternalError
			}
		}
		self = value
	}
}

enum Norm {
	case L1;
	case L2;
	case LInfinity;

	private var _rawValue: la_norm_t {
		var value: Int32 {
			switch self {
			case .L1:        return LA_L1_NORM
			case .L2:        return LA_L2_NORM
			case .LInfinity: return LA_LINF_NORM
			}
		}
		return la_norm_t(value)
	}
}

final public class Matrix: Equatable {

	private let _matrix: la_object_t

	private init (_ matrix: la_object_t) {
		self._matrix = matrix
	}

	convenience init (_
		elements: [Double],
		rows: UInt,
		columns: UInt,
		hint: Hint = .None,
		attribute: Attribute = .None) {
			assert(elements.count > 0, "Matrix must have at least one element");
			assert(rows > 0, "Matrix must have at least one row");
			assert(columns > 0, "Matrix must have at least one column");
			assert(UInt(elements.count) == rows * columns, "Elements count must equal to rows times columuns");
			self.init(la_matrix_from_double_buffer(elements, rows, columns, columns, hint._rawValue, attribute._rawValue))
	}

	convenience init (_
		rows: [Double]...) {
			assert(rows.count > 0, "Matrix must have at least one row");
			assert(rows[0].count > 0, "Matrix must have at least one column");
			self.init([].join(rows), rows: UInt(rows.count), columns: UInt(rows[0].count))
	}

	convenience init (zero
		rows: UInt,
		columns: UInt,
		attribute: Attribute = .None) {
			let elements = [Double](count: Int(rows * columns), repeatedValue: 0.0)
			self.init(la_matrix_from_double_buffer(elements, UInt(elements.count), 1, 1, Hint.None._rawValue, attribute._rawValue))
	}

	convenience init (identity
		size: UInt,
		attribute: Attribute = .None) {
			self.init(la_identity_matrix(size, UInt32(LA_SCALAR_TYPE_DOUBLE), attribute._rawValue))
	}

	convenience init (diagonal
		elements: [Double],
		index: Int,
		attribute: Attribute = .None) {
			let vector = la_matrix_from_double_buffer(elements, UInt(elements.count), 1, 1, Hint.None._rawValue, attribute._rawValue)
			self.init(la_diagonal_matrix_from_vector(vector, index))
	}
}

extension Matrix {

	var rowCount: UInt {
		return UInt(la_matrix_rows(self._matrix))
	}

	var columnCount: UInt {
		return UInt(la_matrix_cols(self._matrix))
	}

	var matrix: [[Double]] {
		var columns = [[Double]]()
		for j in 0 ..< self.columnCount {
			var rows = [Double]()
			for i in 0 ..< self.rowCount {
				rows.append(self[i, j])
			}
			columns.append(rows)
		}
		return columns
	}

	var elements: [Double] {
		var elements = [Double](count: Int(self.rowCount * self.columnCount), repeatedValue: 0.0)
		let status = la_matrix_to_double_buffer(&elements, self.columnCount, self._matrix)
		return elements
	}

	func getElements(callback: (elements: [Double], status: Status) -> Void) {
		var elements = [Double](count: Int(self.rowCount * self.columnCount), repeatedValue: 0.0)
		let status = la_matrix_to_double_buffer(&elements, self.columnCount, self._matrix)
		callback(elements: elements, status: Status(status))
	}

	func norm(norm: Norm) -> Double {
		return la_norm_as_double(self._matrix, norm._rawValue)
	}
}

extension Matrix: Printable {
	public var description: String {
		return NSArray(array: self.matrix.map({
			NSArray(array: $0.map({
				String(format: "%.13f", $0)
			})).componentsJoinedByString(", ")
		})).componentsJoinedByString("; ")
	}
}

extension Matrix {

	var transposedMatrix: Matrix {
		return Matrix(la_transpose(self._matrix))
	}

	func normalizedVector(norm: Norm) -> Matrix {
		return Matrix(la_normalized_vector(self._matrix, norm._rawValue))
	}

	func submatrix(rowRange: Range<UInt>, columnRange: Range<UInt>) -> Matrix {
		return Matrix(
			la_matrix_slice(
				self._matrix,
				la_index_t(rowRange.startIndex),
				la_index_t(columnRange.startIndex), 1, 1,
				rowRange.endIndex - rowRange.startIndex,
				columnRange.endIndex - columnRange.startIndex))
	}

	func rowVector(row: UInt) -> Matrix {
		return Matrix(la_vector_from_matrix_row(self._matrix, row))
	}

	func columnVector(column: UInt) -> Matrix {
		return Matrix(la_vector_from_matrix_col(self._matrix, column))
	}

	func diagonalVector(index: Int) -> Matrix {
		return Matrix(la_vector_from_matrix_diagonal(self._matrix, index))
	}
}

extension Matrix {

	subscript(index: UInt) -> Double {
		return self.elements[Int(index)]
	}

	subscript(rowRange: Range<UInt>, columnRange: Range<UInt>) -> Matrix {
		return self.submatrix(rowRange, columnRange: columnRange)
	}

	subscript(row: UInt, col:UInt) -> Double {
		return self[row...row, col...col].elements[0]
	}
}

extension Matrix {

	func scale(scalar: Double) -> Matrix {
		return Matrix(la_scale_with_double(self._matrix, scalar))
	}

	func sum(matrix: Matrix) -> Matrix {
		return Matrix(la_sum(self._matrix, matrix._matrix))
	}

	func difference(matrix: Matrix) -> Matrix {
		return Matrix(la_difference(self._matrix, matrix._matrix))
	}

	func elementwiseProduct(matrix: Matrix) -> Matrix {
		return Matrix(la_elementwise_product(self._matrix, matrix._matrix))
	}

	func innerProduct(matrix: Matrix) -> Matrix {
		return Matrix(la_inner_product(self._matrix, matrix._matrix))
	}

	func outerProduct(matrix: Matrix) -> Matrix {
		return Matrix(la_outer_product(self._matrix, matrix._matrix))
	}

	func matrixProduct(matrix: Matrix) -> Matrix {
		return Matrix(la_matrix_product(self._matrix, matrix._matrix))
	}
}

public func == (left: Matrix, right: Matrix) -> Bool {
	return (
		left.rowCount == right.rowCount &&
		left.columnCount == right.columnCount &&
		(0 ..< left.elements.count).map({$0}).reduce(true, combine: { (flag, index) -> Bool in
			flag && left.elements[index] == right.elements[index]
		}))
}

public func * (left: Double, right: Matrix) -> Matrix {
	return right.scale(left)
}

public func + (left: Matrix, right: Matrix) -> Matrix {
	return left.sum(right)
}

public func - (left: Matrix, right: Matrix) -> Matrix {
	return left.difference(right)
}
