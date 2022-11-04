package poly.log8415;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

import org.apache.hadoop.fs.Path;
import org.apache.hadoop.conf.*;
import org.apache.hadoop.io.*;
import org.apache.hadoop.mapred.*;
import org.apache.hadoop.util.*;

public class Recommendation {

  public static class Map extends MapReduceBase implements Mapper<LongWritable, Text, Text, Text> {
    
    private final static IntWritable one = new IntWritable(1);

    public void map(LongWritable key, Text value, OutputCollector<Text, Text> output, Reporter reporter)
        throws IOException {
      // Split each parsed line into a list      
      String line[] = value.toString().split("\t");
      //Retrieve the user value 
      String user = line[0];
      // Initialize a list of string that will contain the list of friends delimeted by ','
      List<String> friends = new ArrayList<String>();
      
      // Ensure that that each line contains a user and friends   
      if (line.length == 2) {
        //Tokenizing the friends list using ',' as delimiter
        StringTokenizer tokenizer = new StringTokenizer(line[1], ",");
        //Iterate through friends list 
        while (tokenizer.hasMoreTokens()) {
          // Retrieve the friend value
          String friend = tokenizer.nextToken();
          // Add retrieved friend to the list
          friends.add(friend);
          // Output a datagram of each user with his friend that is a (user,(friend(i),negative-flag)) of the form (1, (2,-1000000)) (1, (3,-100000))
          output.collect(new Text(user), new Text(friend + "," + new IntWritable(-10000000).toString()));
        }
        
        /* Iterate through friends list to map a key value of potential relation between them
        ** Let's say that we have this line : 1  2,3
        ** We'll map the list of friends as key value+flag as follow:
        ** (2, (3,1)) (3, (2,1))
        */
        for (int i = 0; i < friends.size(); i++) {
          for (int j = i + 1; j < friends.size(); j++) {
            // Output a datagram of each friend as key with his all potential friend but this time with an initial flag equal to 1
            output.collect(new Text(friends.get(i)), new Text(friends.get(j) + "," + one.toString()));
            output.collect(new Text(friends.get(j)), new Text(friends.get(i) + "," + one.toString()));
          }
        }
      }
    }
  }
}