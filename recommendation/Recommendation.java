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

  public static class Reduce extends MapReduceBase implements Reducer<Text, Text, Text, Text> {
  
    // Initialize a hashmap that will contain the collected key,value 
    HashMap<String, HashMap<String, Integer>> reduceMap = new HashMap<>();

    public void reduce(Text key, Iterator<Text> values, OutputCollector<Text, Text> output, Reporter reporter)
        throws IOException {

      // If the key does not exist in the reducemap, add the key with an empty map value 
      if (reduceMap.get(key) == null)
      {
        reduceMap.put(key.toString(), new HashMap<>());  
      }
              
      // Iterate through key values
      while (values.hasNext()) {
        // Split values by the delimter ',' to get into a list the potiential friend or friend with his flag value
        String valueFlag[] = values.next().toString().split(",");
        // Ensure that the list contains two values
        if (valueFlag.length == 2) {
          // Get the potential or friend value
          String potentialFriend = valueFlag[0];
          // If the key does not contain the potentialFriend as value key into the reduceMap, add it as new map with the flag value
          if (!reduceMap.get(key.toString()).containsKey(potentialFriend))
              reduceMap.get(key.toString()).put(potentialFriend, Integer.parseInt(valueFlag[1]));
          else {
              //Otherwise, update the existing value
              int existingFlagValue = reduceMap.get(key.toString()).get(potentialFriend);
              reduceMap.get(key.toString()).put(potentialFriend, existingFlagValue + Integer.parseInt(valueFlag[1]));
            }
          }
      }

      // Filter out values with negative flag since they are already friends with the user and sort remaining value in desc order
      HashMap<String, Integer> sorted = reduceMap.get(key.toString())
                                                   .entrySet()
                                                   .stream()
                                                   .filter(value -> value.getValue() > 0)
                                                   .sorted(Collections.reverseOrder(java.util.Map.Entry.comparingByValue()))
                                                   .collect(Collectors.toMap(java.util.Map.Entry::getKey, java.util.Map.Entry::getValue,(a, b) -> b, LinkedHashMap::new));
    
      //Update the key value
      reduceMap.put(key.toString(), sorted);
      
      // Keep only the first 10 recommended users  
      List<String> recommendedList = reduceMap.get(key.toString())
                                          .keySet()
                                          .stream()
                                          .limit(10)
                                          .collect(Collectors.toList());
      
      //Output the final datagrams with the recommendation list of users separated by ','
      output.collect(key, new Text(String.join(",",recommendedList)));
    }
  }

  // Main
  public static void main(String[] args) throws Exception {
    //Set up the haoop job
    JobConf conf = new JobConf(Recommendation.class);
    //Set the user-specified job name.
    conf.setJobName("recommendation");

    //Set the key/value class for the job output data.
    conf.setOutputKeyClass(Text.class);
    conf.setOutputValueClass(Text.class);

    //Set the Mapper/reducer class for the job.
    conf.setMapperClass(Map.class);
    conf.setReducerClass(Reduce.class);

    //Set the Input/Output format implementation for the map-reduce job.
    conf.setInputFormat(TextInputFormat.class);
    conf.setOutputFormat(TextOutputFormat.class);

    //Set the array of Paths as the list of inputs/outputs for the map-reduce job
    FileInputFormat.setInputPaths(conf, new Path(args[0]));
    FileOutputFormat.setOutputPath(conf, new Path(args[1]));

    //Submit the job
    JobClient.runJob(conf);
  }
}