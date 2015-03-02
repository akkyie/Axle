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

public protocol ElementType: Comparable, Printable {
	class var la_matrix_from_buffer: (UnsafePointer<Self>, la_count_t, la_count_t, la_count_t, la_hint_t, la_attribute_t) -> la_object_t! { get }
	class var la_matrix_to_buffer: (UnsafeMutablePointer<Self>, la_count_t, la_object_t!) -> la_status_t  { get }
	class var la_norm: (la_object_t!, la_norm_t) -> Self { get }
	class var la_scale: (la_object_t!, Self) -> la_object_t! { get }
	class var la_scalar_type: Int32 { get }
	init(Double)
}

extension Double: ElementType {
	public static var la_matrix_from_buffer: (UnsafePointer<Double>, la_count_t, la_count_t, la_count_t, la_hint_t, la_attribute_t) -> la_object_t! {
		return la_matrix_from_double_buffer
	}

	public static var la_matrix_to_buffer: (UnsafeMutablePointer<Double>, la_count_t, la_object_t!) -> la_status_t {
		return la_matrix_to_double_buffer
	}

	public static var la_norm: (la_object_t!, la_norm_t) -> Double {
		return la_norm_as_double
	}

	public static var la_scale: (la_object_t!, Double) -> la_object_t! {
		return la_scale_with_double
	}

	public static var la_scalar_type: Int32 = LA_SCALAR_TYPE_DOUBLE
}

extension Float: ElementType {
	public static var la_matrix_from_buffer: (UnsafePointer<Float>, la_count_t, la_count_t, la_count_t, la_hint_t, la_attribute_t) -> la_object_t! {
		return la_matrix_from_float_buffer
	}

	public static var la_matrix_to_buffer: (UnsafeMutablePointer<Float>, la_count_t, la_object_t!) -> la_status_t {
		return la_matrix_to_float_buffer
	}

	public static var la_norm: (la_object_t!, la_norm_t) -> Float {
		return la_norm_as_float
	}

	public static var la_scale: (la_object_t!, Float) -> la_object_t! {
		return la_scale_with_float
	}

	public static var la_scalar_type: Int32 = LA_SCALAR_TYPE_FLOAT
}

public enum Hint {
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

public enum Attribute {
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

public enum Status {
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

public enum Norm {
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

final public class Matrix <T: ElementType> : Equatable {
	private let _matrix: la_object_t

	private init (_ matrix: la_object_t) {
		self._matrix = matrix
	}

	public convenience init <T: ElementType> (_
		elements: [T],
		rows: UInt,
		columns: UInt,
		hint: Hint = .None,
		attribute: Attribute = .None) {
			assert(elements.count > 0, "Matrix must have at least one element");
			assert(rows > 0, "Matrix must have at least one row");
			assert(columns > 0, "Matrix must have at least one column");
			assert(UInt(elements.count) == rows * columns, "Elements count must equal to rows times columuns");
			self.init(T.la_matrix_from_buffer(elements, rows, columns, columns, hint._rawValue, attribute._rawValue))
	}

	public convenience init (_ rows: [T]...) {
			assert(rows.count > 0, "Matrix must have at least one row");
			assert(rows[0].count > 0, "Matrix must have at least one column");
			self.init([].join(rows), rows: UInt(rows.count), columns: UInt(rows[0].count))
	}

	public convenience init (zero
		rows: UInt,
		columns: UInt,
		attribute: Attribute = .None) {
			let elements = [T](count: Int(rows * columns), repeatedValue: T(0.0))
			self.init(T.la_matrix_from_buffer(elements, UInt(elements.count), 1, 1, Hint.None._rawValue, attribute._rawValue))
	}

	public convenience init (identity
		size: UInt,
		attribute: Attribute = .None) {
			self.init(la_identity_matrix(size, UInt32(T.la_scalar_type), attribute._rawValue))
	}

	public convenience init (diagonal
		elements: [T],
		index: Int,
		attribute: Attribute = .None) {
			let vector = T.la_matrix_from_buffer(elements, UInt(elements.count), 1, 1, Hint.None._rawValue, attribute._rawValue)
			self.init(la_diagonal_matrix_from_vector(vector, index))
	}
}

public extension Matrix {
	public var rowCount: UInt {
		return UInt(la_matrix_rows(self._matrix))
	}

	public var columnCount: UInt {
		return UInt(la_matrix_cols(self._matrix))
	}

	public var matrix: [[T]] {
		var columns = [[T]]()
		for j in 0 ..< self.columnCount {
			var rows = [T]()
			for i in 0 ..< self.rowCount {
				rows.append(self[i, j])
			}
			columns.append(rows)
		}
		return columns
	}

	public var elements: [T] {
		var elements = [T](count: Int(self.rowCount * self.columnCount), repeatedValue: T(0.0))
		let status = T.la_matrix_to_buffer(&elements, self.columnCount, self._matrix)
		return elements
	}

	public func getElements(callback: (elements: [T], status: Status) -> Void) {
		var elements = [T](count: Int(self.rowCount * self.columnCount), repeatedValue: T(0.0))
		let status = T.la_matrix_to_buffer(&elements, self.columnCount, self._matrix)
		callback(elements: elements, status: Status(status))
	}

	public func norm(norm: Norm) -> T {
		return T.la_norm(self._matrix, norm._rawValue)
	}
}

extension Matrix: Printable {
	public var description: String {
		return NSArray(array: self.matrix.map({ (elements: [T]) -> String in
			return NSArray(array: elements.map({ (element: T) -> String in
				return element.description
			})).componentsJoinedByString(", ")
		})).componentsJoinedByString("; ")
	}
}

public extension Matrix {
	public var transposedMatrix: Matrix {
		return Matrix(la_transpose(self._matrix))
	}

	public func normalizedVector(norm: Norm) -> Matrix {
		return Matrix(la_normalized_vector(self._matrix, norm._rawValue))
	}

	public func submatrix(rowRange: Range<UInt>, columnRange: Range<UInt>) -> Matrix {
		return Matrix(
			la_matrix_slice(
				self._matrix,
				la_index_t(rowRange.startIndex),
				la_index_t(columnRange.startIndex), 1, 1,
				rowRange.endIndex - rowRange.startIndex,
				columnRange.endIndex - columnRange.startIndex))
	}

	public func rowVector(row: UInt) -> Matrix {
		return Matrix(la_vector_from_matrix_row(self._matrix, row))
	}

	public func columnVector(column: UInt) -> Matrix {
		return Matrix(la_vector_from_matrix_col(self._matrix, column))
	}

	public func diagonalVector(index: Int) -> Matrix {
		return Matrix(la_vector_from_matrix_diagonal(self._matrix, index))
	}
}

public extension Matrix {
	public subscript(index: UInt) -> T {
		return self.elements[Int(index)]
	}

	public subscript(rowRange: Range<UInt>, columnRange: Range<UInt>) -> Matrix {
		return self.submatrix(rowRange, columnRange: columnRange)
	}

	public subscript(row: UInt, col:UInt) -> T {
		return self[row...row, col...col].elements[0]
	}
}

public extension Matrix {
	public func scale(scalar: T) -> Matrix {
		return Matrix(T.la_scale(self._matrix, scalar))
	}

	public func sum(matrix: Matrix) -> Matrix {
		return Matrix(la_sum(self._matrix, matrix._matrix))
	}

	public func difference(matrix: Matrix) -> Matrix {
		return Matrix(la_difference(self._matrix, matrix._matrix))
	}

	public func elementwiseProduct(matrix: Matrix) -> Matrix {
		return Matrix(la_elementwise_product(self._matrix, matrix._matrix))
	}

	public func innerProduct(matrix: Matrix) -> Matrix {
		return Matrix(la_inner_product(self._matrix, matrix._matrix))
	}

	public func outerProduct(matrix: Matrix) -> Matrix {
		return Matrix(la_outer_product(self._matrix, matrix._matrix))
	}

	public func matrixProduct(matrix: Matrix) -> Matrix {
		return Matrix(la_matrix_product(self._matrix, matrix._matrix))
	}
}

public func == <T: ElementType> (left: Matrix<T>, right: Matrix<T>) -> Bool {
	return (
		left.rowCount == right.rowCount &&
		left.columnCount == right.columnCount &&
		(0 ..< left.elements.count).map({$0}).reduce(true, combine: { (flag, index) -> Bool in
			flag && left.elements[index] == right.elements[index]
		}))
}

public func * <T: ElementType> (left: T, right: Matrix<T>) -> Matrix<T> {
	return right.scale(left)
}

public func + <T: ElementType> (left: Matrix<T>, right: Matrix<T>) -> Matrix<T> {
	return left.sum(right)
}

public func - <T: ElementType> (left: Matrix<T>, right: Matrix<T>) -> Matrix<T> {
	return left.difference(right)
}
