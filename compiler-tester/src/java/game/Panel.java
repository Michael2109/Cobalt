package game;import javax.swing.JPanel;
import java.awt.Graphics;public final class Panel extends JPanel implements Runnable{
Thread thread=new Thread(this);
int x=100;
int y=100;
int dx=1;
int dy=1;
public Panel(){
thread.start();}
public void update(){
x=x + dx;
y=y + dy;
if(x < 0 || x > 750){
dx=dx * -1;}
if(y < 0 || y > 550){
dy=dy * -1;}}
public void paint(Graphics g){
super.paintComponent(g);
g.drawRect(x, y, 50, 50);}
public void run(){
try{while(true){
Thread.sleep(7);
update();
repaint();}}
catch(Exception e){}}}