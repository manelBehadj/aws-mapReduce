"""
In this python script we will parse the generated file from the comparaison function and display results using plotly graphs
The parsed files looks like :
buchanj-midwinter-00-t.txt
real 10.85
user 17.29
sys 0.93
"""

import sys
import os
import pandas as pd
import plotly.graph_objects as go


"""
Parse the file that contains the output of the wordcount execution time
:param file_name: name of the file to parse
:return: a list of rows that contains each line as follow [["file_name", "real", "user", "sys" ],[...],...] 
"""
def parse_file(file_name):
    # Initlize a list of rows that will contain all lines as matrix
    rows_list = []
    print(file_name)
    with open(file_name) as f:
        # Read all lines into a list
        lines = f.readlines()
        # Initlize a row list that will contain each line
        new_row = []
        # Iterate through each line
        for n, line in enumerate(lines):
            # Check if the line contains the file name
            if ".txt" in line:
                # If the row list contains elements that means that we went through all file metrics
                if new_row:
                    # Append the final list with the parsed file metrics
                    rows_list.append(new_row)
                    # Initlize a new row list
                    new_row = []
                    # Fill the new row list with next file name
                    new_row.append(line.split()[0])
                else:
                    # Handle the first line
                    new_row.append(line.split()[0])
            else:
                # Collect lines related to a file name
                new_row.append(float(line.split()[1]))
                # Handle the last line
                if len(lines) - 1 == n:
                    rows_list.append(new_row)

    return rows_list


"""
Generate a dataframe
:param rows_list: list of the dataframe rows 
:return: a dataframe that will contain metrics by file name 
"""
def generate_dataframe(rows_list):
    df = pd.DataFrame(
        rows_list, columns=["file_name", "real_time", "user_time", "sys_time"]
    )
    return df


"""
Calculate the average of ech metric(real_time,user_time,sys_time) by file name
:param df: datafarme that contains collected metrics 
:return: a new dataframe with metric average by file name
"""
def get_average(df):
    df_average = df.groupby(df["file_name"]).agg(
        {"real_time": ["mean"], "user_time": ["mean"], "sys_time": ["mean"]}
    )
    df_average.columns = [
        "mean real time",
        "mean user time",
        "mean sys time",
    ]
    df_average.reset_index(inplace=True)
    return df_average


"""
Display the comparaison results between linux,hadoop and hadoop,spark using plotly
:param df1: dataframe that contains the results of the first tool
:param df: dataframe that contains the results of the second tool 
:return: graph diagrams
"""
def compare_result(df1, df2, name_1, name_2):
    fig = go.Figure()
    fig.add_trace(
        go.Bar(
            x=df1["file_name"],
            y=df1["mean real time"],
            name=f"{name_1}  real time",
            marker_color="#ffa500",
        )
    )
    fig.add_trace(
        go.Bar(
            x=df2["file_name"],
            y=df2["mean real time"],
            name=f"{name_2} real time",
            marker_color="#008000",
        )
    )
    fig.show()



"""
Main
"""
# Get the root directory to be able to read fils from sibling directory
ROOT_DIR = os.path.realpath(os.path.join(os.path.dirname(__file__), ".."))

# Retrive files name from args
first_file_path = sys.argv[1]
second_file_path = sys.argv[2]

# Parse files
first_file_metrics = parse_file(ROOT_DIR + first_file_path)
second_file_metrics = parse_file(ROOT_DIR + second_file_path)

# Generate dataframes
first_metrics_df = generate_dataframe(first_file_metrics)
second_metrics_df = generate_dataframe(second_file_metrics)

# Calculate average
first_metrics_average = get_average(first_metrics_df)
second_metrics_average = get_average(second_metrics_df)

# Retrieve the source(linux,hadoop,spark) of metrics from the file name
first_fig_name = os.path.basename(sys.argv[1]).split("/")[-1].split("_")[0]
second_fig_name = os.path.basename(sys.argv[2]).split("/")[-1].split("_")[0]

# Display final resluts
compare_result(
    first_metrics_average,
    second_metrics_average,
    first_fig_name,
    second_fig_name,
)
