/*
 * Jakefile
 * WyzihatKit
 *
 * Created by Alexander Ljungberg on April 14, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    OS = require("os");

app ("wyzihatkit", function(task)
{
    task.setBuildIntermediatesPath(FILE.join(ENV["CAPP_BUILD"], "WyzihatKit.build", configuration));
    task.setBuildPath(FILE.join(ENV["CAPP_BUILD"], configuration));

    task.setProductName("WyzihatKit");
    task.setIdentifier("wyzihatkit");
    task.setVersion("1.0");
    task.setAuthor("Alexander Ljungberg");
    task.setEmail("aljungberg@wireload.net");
    task.setSummary("WyzihatKit");
    task.setSources((new FileList("**/*.j")).exclude(FILE.join("Build", "**")).exclude(FILE.join("sample", "**")).exclude(FILE.join("sample.dist", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, "WyzihatKit"));
    print("----------------------------");
}

task ("default", ["wyzihatkit"], function()
{
    printResults(configuration);
});

task ("build", ["default"]);

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("install", ["debug", "release"])
