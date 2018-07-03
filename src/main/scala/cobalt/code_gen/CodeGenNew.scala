package cobalt.code_gen

import java.io.PrintWriter

import cobalt.ast.IRNew._
import cobalt.ast.IRUtils

import scala.tools.asm.{Opcodes, _}
import scala.tools.asm.util.CheckClassAdapter;

object CodeGenNew {

  val version = 49

  def genModelCode(model: ModelIR): Array[Byte] = {
    model match {
      case classModel: ClassModelIR => {
        val cw = new ClassWriter(ClassWriter.COMPUTE_MAXS | ClassWriter.COMPUTE_FRAMES)
        cw.visit(version, Opcodes.ACC_PUBLIC + Opcodes.ACC_SUPER, classModel.nameSpace + "/" + classModel.name, null, "java/lang/Object", null)
        val constructor = cw.visitMethod(Opcodes.ACC_PUBLIC, "<init>", "()V", null, null)
        constructor.visitVarInsn(Opcodes.ALOAD, 0)
        constructor.visitMethodInsn(Opcodes.INVOKESPECIAL, "java/lang/Object", "<init>", "()V")
        constructor.visitInsn(Opcodes.RETURN)
        constructor.visitMaxs(0, 0)
        constructor.visitEnd()
        classModel.methods.foreach(m => genCode(cw, m))
        cw.visitEnd()

        val pw = new PrintWriter(System.out)
        CheckClassAdapter.verify(new ClassReader(cw.toByteArray), true, pw)

        cw.toByteArray


      }
    }
  }

  def genCode(cw: ClassWriter, method: MethodIR): Unit = {

      val mv = cw.visitMethod(Opcodes.ACC_PUBLIC, method.name, String.format("(%s)V", method.fields.map(x => IRUtils.typeToBytecodeType(x._2))), null, null)
      method.body.foreach(x => genCode(mv, x))
      mv.visitInsn(Opcodes.RETURN)
      mv.visitMaxs(0, 0)
      mv.visitEnd()

  }

  def genCode(mv: MethodVisitor, expression: ExpressionIR): Unit = {
    expression match {
     /* case aBinary: ABinaryIR => {
        genCode(mv, aBinary.expression1)
        genCode(mv, aBinary.expression2)
        val instruction = IRUtils.getArithmeticOperator(aBinary.op, aBinary.expression1, aBinary.expression2)
        mv.visitInsn(instruction)
      }
      case boolConst: BoolConstIR => mv.visitIntInsn(Opcodes.BIPUSH,
        if (boolConst.value.equals(true)) {
          1
        } else {
          0
        })
      case blockStmt: BlockExprIR => blockStmt.expressions.foreach(x => genCode(mv, x))*/
      case intConst: IntConstIR => mv.visitIntInsn(Opcodes.BIPUSH, intConst.value.toInt)
      /*case longConst: LongConstIR => mv.visitLdcInsn(longConst.value.toLong)
      case floatConst: FloatConstIR => mv.visitLdcInsn(floatConst.value.toFloat)
      case doubleConst: DoubleConstIR => mv.visitLdcInsn(doubleConst.value.toDouble)*/
      case methodCall: MethodCallIR => {
        mv.visitFieldInsn(methodCall.fieldOpcode, methodCall.fieldOwner, methodCall.fieldName, methodCall.fieldDesc)
        genCode(mv, methodCall.args)
        mv.visitMethodInsn(methodCall.methodOpcode, methodCall.methodOwner, methodCall.methodName, methodCall.methodDesc)
      }
      /*case stringLiteral: StringLiteralIR => mv.visitLdcInsn(stringLiteral.value)*/
    }
  }

  def genCode(mv: MethodVisitor, statement: StatementIR): Unit = {
    statement match {
      /*case assign: AssignIR => {
        genCode(mv, assign.block)
        mv.visitVarInsn(IRUtils.getStoreOperator(assign.block), assign.id)
      }*/
      /*case blockStmt: BlockStmtIR => blockStmt.statements.foreach(x => genCode(mv, x))*/
      case doBlock: DoBlockIR => genCode(mv, doBlock.asInstanceOf[BlockIR])
      case exprAsStmt: ExprAsStmtIR => genCode(mv, exprAsStmt.expressionIR)
      /*case ifStmt: IfIR => {
        val trueLabel = new Label
        val endLabel = new Label
        genCode(mv, ifStmt.condition)
        mv.visitJumpInsn(Opcodes.IFEQ, trueLabel)
        genCode(mv, ifStmt.ifBlock)
        mv.visitJumpInsn(Opcodes.GOTO, endLabel)
        mv.visitLabel(trueLabel)
        genCode(mv, ifStmt.elseBlock.getOrElse(BlockStmtIR(Seq())))
        mv.visitLabel(endLabel)
      }*/
      case inline: InlineIR => genCode(mv, inline.asInstanceOf[BlockIR])
    }
  }

  def genCode(mv: MethodVisitor, block: BlockIR): Unit = {
    block match {
      case doBlock: DoBlockIR => genCode(mv, doBlock.statement)
      case inline: InlineIR => genCode(mv, inline.expression)
    }
  }
}