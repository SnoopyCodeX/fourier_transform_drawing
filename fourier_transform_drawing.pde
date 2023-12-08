import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

ArrayList<PVector> path = new ArrayList<>();
JSONArray dataJSONPath;

ArrayList<Map<String, Float>> dftsX;
ArrayList<Map<String, Float>> dftsY;
Float[] signalsX;
Float[] signalsY;

float time = 0;
int col = 255;

/**
 * Increase or decrease the value of
 * this to make the drawing faster or slower.
 *
 * This will skip some points in the paths (the json file provided)
 * which will make the drawing faster. This is useful
 * when you have a lot of points.
 *
 * Example, try loading the "train_path.json" in the code below
 * at line 39 and leave the value of this `skip` variable to 1.
 * You will notice that the drawing is a bit slow because the
 * paths of the drawing has a lot of points. Now, try changing the
 * value of this `skip` variable to 8 and re-run this sketch. Now it's
 * fast. Only do this if you have a lot of points in your drawing.
 */
int skip = 1;

void setup() {
  size(1100, 900);
  windowTitle("Fourier Transform Drawing");
  
  // Load json file that contains the paths
  dataJSONPath = loadJSONArray("train_path.json");
  
  ArrayList<Float> tempX = new ArrayList<>();
  ArrayList<Float> tempY = new ArrayList<>();
  
  for(int i = 0; i < dataJSONPath.size(); i += skip) {
    JSONObject dataPath = dataJSONPath.getJSONObject(i);
    
    tempX.add(dataPath.getFloat("x"));
    tempY.add(dataPath.getFloat("y"));
  }
  
  signalsX = tempX.toArray(new Float[tempX.size()]);
  signalsY = tempY.toArray(new Float[tempY.size()]);
  
  dftsX = dft(signalsX);
  dftsY = dft(signalsY);
  
  dftsX.sort(new DFTSorter());
  dftsY.sort(new DFTSorter());
}

void draw() {
  background(0);
  
  PVector vx = epiCycles(width / 3, 50f, 0, dftsX);
  PVector vy = epiCycles(100f, height / 4, HALF_PI, dftsY);
  PVector vector = new PVector(vx.x, vy.y);
  path.add(0, vector);
  
  line(vx.x, vx.y, vector.x, vector.y);
  line(vy.x, vy.y, vector.x, vector.y);
  stroke(col, 255 - col, 100);
  beginShape();
  noFill();
  for(int i = 0; i < path.size(); i++)
    vertex(path.get(i).x, path.get(i).y);
  endShape();
  
  float dt = TWO_PI / dftsY.size();
  time += dt;
  
  if(time >= TWO_PI) {
    path = new ArrayList<>();
    time = 0;
    col = col - 50;
    
    if(col <= 0)
      col = 255;
  }
}

PVector epiCycles(float x, float y, float rotation, ArrayList<Map<String, Float>> fourier) {
  for(int i = 0; i < fourier.size(); i++) {
    float prevX = x;
    float prevY = y;
    
    float frequency = fourier.get(i).get("frequency");
    float radius = fourier.get(i).get("amplitude");
    float phase = fourier.get(i).get("phase");
    
    x += radius * cos(frequency * time + phase + rotation);
    y += radius * sin(frequency * time + phase + rotation);
    
    stroke(255, 100);
    noFill();
    ellipse(prevX, prevY, radius * 2, radius * 2);
    stroke(255);
    line(prevX, prevY, x, y);
  }
  
  return new PVector(x, y);
}

/**
 * Discrete Fourier Transform
 *
 * This is used to calculate the dft for
 * the given array of signals.
 *
 *@param {int[]} x The array of signals
 *@return {Map<Integer, Map<String, Float>>}
 */
ArrayList<Map<String, Float>> dft(Float[] x) {
  ArrayList<Map<String, Float>> X = new ArrayList<>();
  int N = x.length;
  
  for(int k = 0; k < N; k++) {
    float re = 0;
    float im = 0;
    
    for(int n = 0; n < N; n++) {
      float phi = (TWO_PI * k * n) / N;
      
      re += x[n] * cos(phi);
      im -= x[n] * sin(phi);
    }
    
    re = re / N;
    im = im / N;
    
    float frequency = k;
    float amplitude = sqrt(re*re + im*im);
    float phase = atan2(im, re);
    
    Map<String, Float> temp = new HashMap<>();
    temp.put("re", re);
    temp.put("im", im);
    temp.put("frequency", frequency);
    temp.put("amplitude", amplitude);
    temp.put("phase", phase);
    X.add(k, temp);
  }
  
  return X;
}

/**
 * DFT Sorter class.
 * This will be used to sort the calculated DFTs
 * of each signals by their amplitudes.
 */
class DFTSorter implements Comparator<Map<String, Float>> {
  @Override
  public int compare(Map<String, Float> a, Map<String, Float> b) {
    return b.get("amplitude").compareTo(a.get("amplitude")); 
  }
}
