package game;import javax.swing.JPanel;
import java.awt.Graphics;public final class Panel extends JPanel implements Runnable{
public boolean alive=true;public boolean alive(){return true;}
private Thread thread=new Thread(this);private Thread thread(){return new Thread(this);} private int x=50;private int x(){return 50;} private int y=100;private int y(){return 100;} private int dx=1;private int dx(){return 1;} private int dy=1;private int dy(){return 1;}public Panel(){
System.out.println("Something");
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