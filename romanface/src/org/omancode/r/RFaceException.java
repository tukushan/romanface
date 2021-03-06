package org.omancode.r;

import java.io.IOException;

import org.omancode.r.types.REXPAttr;
import org.rosuda.REngine.REXP;

/**
 * Exception generated by R interface code.
 * 
 * @author Oliver Mannion
 * @version $Revision$
 */
public class RFaceException extends IOException {

	/**
	 * Serialization ID.
	 */
	private static final long serialVersionUID = -2048430471489617308L;

	/**
	 * Constructs a new exception with the specified detail message and cause.
	 * <p>
	 * Note that the detail message associated with <code>cause</code> is
	 * <i>not</i> automatically incorporated in this exception's detail message.
	 * 
	 * @param message
	 *            the detail message (which is saved for later retrieval by the
	 *            {@link #getMessage()} method).
	 * @param cause
	 *            the cause (which is saved for later retrieval by the
	 *            {@link #getCause()} method). (A <tt>null</tt> value is
	 *            permitted, and indicates that the cause is nonexistent or
	 *            unknown.)
	 */
	public RFaceException(String message, Throwable cause) {
		super(message, cause);
	}

	/**
	 * Constructs a new exception with the specified detail message. The cause
	 * is not initialized, and may subsequently be initialized by a call to
	 * {@link #initCause}.
	 * 
	 * @param message
	 *            the detail message. The detail message is saved for later
	 *            retrieval by the {@link #getMessage()} method.
	 */
	public RFaceException(String message) {
		super(message);
	}

	/**
	 * Constructs a new exception with the specified cause and a detail message
	 * of <tt>(cause==null ? null : cause.toString())</tt> (which typically
	 * contains the class and detail message of <tt>cause</tt>). This
	 * constructor is useful for exceptions that are little more than wrappers
	 * for other throwables (for example,
	 * {@link java.security.PrivilegedActionException}).
	 * 
	 * @param cause
	 *            the cause (which is saved for later retrieval by the
	 *            {@link #getCause()} method). (A <tt>null</tt> value is
	 *            permitted, and indicates that the cause is nonexistent or
	 *            unknown.)
	 */
	public RFaceException(Throwable cause) {
		super(cause);
	}

	/**
	 * Create an {@link RFaceException} with details of the rexp included
	 * in the message.
	 * 
	 * @param rexp
	 *            rexp to interrogate
	 * @param message
	 *            message
	 */
	public RFaceException(REXP rexp, String message) {
		super(createExceptionMessage(null, rexp, message));
	}

	/**
	 * Create an {@link RFaceException} with details of the rexp included
	 * in the message and the original R expression executed.
	 * 
	 * @param expr
	 *            R cmd executed, or {@code null}
	 * @param rexp
	 *            rexp to interrogate
	 * @param message
	 *            message
	 */
	public RFaceException(String expr, REXP rexp, String message) {
		super(createExceptionMessage(expr, rexp, message));
	}

	/**
	 * Create an message with details of the rexp.
	 * 
	 * @param expr
	 *            R cmd executed, or {@code null}
	 * @param rexp
	 *            rexp to interrogate
	 * @param message
	 *            message
	 * @throws RFaceException
	 *             new exception
	 */
	private static String createExceptionMessage(String expr, REXP rexp,
			String message) {

		StringBuffer msg = new StringBuffer(256);

		if (expr != null) {
			msg.append(expr).append(" returned result of ");
		}

		msg.append("class ").append(REXPAttr.getClassAttribute(rexp)).append(
				" with dimensions = ").append(REXPAttr.getDimensions(rexp))
				.append(".\n").append(message);

		return msg.toString();
	}
}
