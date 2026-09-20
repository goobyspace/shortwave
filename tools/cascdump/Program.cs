using System.Globalization;
using TACTSharp;
var options = ParseArguments(args);
var baseDirectory = Require(options, "basedir");
var product = Require(options, "product");
var output = Require(options, "output");
var buildInfoPath = Path.Combine(baseDirectory, ".build.info");

if (!File.Exists(buildInfoPath))
    throw new FileNotFoundException("Could not find .build.info in the installation directory.", buildInfoPath);

var build = new BuildInstance();
build.Settings.BaseDir = baseDirectory;
build.Settings.Product = product;
build.Settings.RootMode = RootInstance.LoadMode.Normal;

var buildInfo = new BuildInfo(buildInfoPath, build.Settings, build.cdn);
var productBuild = buildInfo.Entries.FirstOrDefault(entry =>
    entry.Product.Equals(product, StringComparison.OrdinalIgnoreCase));

if (string.IsNullOrEmpty(productBuild.Product))
    throw new InvalidOperationException("Product '" + product + "' was not found in .build.info.");

build.Settings.BuildConfig = productBuild.BuildConfig;
build.Settings.CDNConfig = productBuild.CDNConfig;
build.cdn.ProductDirectory = productBuild.CDNPath;
build.LoadConfigs(build.Settings.BuildConfig, build.Settings.CDNConfig);
build.Load();

if (build.Root == null)
    throw new InvalidOperationException("The client root manifest could not be loaded.");

var ids = build.Root.GetAvailableFDIDs()
    .Distinct()
    .OrderBy(id => id)
    .Select(id => id.ToString(CultureInfo.InvariantCulture));

Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(output))!);
File.WriteAllLines(output, ids);
Console.WriteLine("Wrote " + product + " FileDataIDs to " + output);

static Dictionary<string, string> ParseArguments(string[] arguments)
{
    var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    for (var index = 0; index < arguments.Length; index++)
    {
        var argument = arguments[index];
        if (!argument.StartsWith("--") || index + 1 >= arguments.Length)
            throw new ArgumentException("Expected --name value arguments.");

        result[argument[2..]] = arguments[++index];
    }

    return result;
}

static string Require(Dictionary<string, string> options, string name)
{
    if (!options.TryGetValue(name, out var value) || string.IsNullOrWhiteSpace(value))
        throw new ArgumentException("Missing --" + name + ".");
    return value;
}
