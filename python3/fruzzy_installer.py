import json
import urllib.request
import sys
from os import path


def install():
    def get_asset(assets):
        def first(items):
            return next(items, None)

        if sys.platform == "win32":
            name = "fruzzy_mod.pyd"
        elif sys.platform == "linux":
            name = "fruzzy_mod.so"
        elif sys.platform == "darwin":
            name = "fruzzy_mod_mac.so"
        else:
            print("unknown platform %s" % sys.platform)

        return first(filter(lambda a: a["name"] == name, assets))

    _json = json.loads(urllib.request.urlopen(urllib.request.Request(
        'https://api.github.com/repos/raghur/fruzzy/releases/latest',
        headers={'Accept': 'application/vnd.github.v3+json'},))
                       .read().decode())
    asset = get_asset(_json["assets"])
    # print(__file__)
    dirname = path.normpath(path.join(path.dirname(__file__), ".."))
    outfile = path.join(dirname, "rplugin/python3/fruzzy_mod")
    extn = ".pyd" if sys.platform == "win32" else ".so"
    altfile = outfile + ".1" + extn
    outfile = outfile + extn
    try:
        print("fruzzy: downloading %s to %s" % (asset['browser_download_url'],
                                                asset['name']))
        urllib.request.urlretrieve(asset['browser_download_url'], outfile)
        print("native mod %s installed - restart vim/nvim if needed" % outfile)
    except PermissionError as e:
        # happens on windows if the mod is loaded
        print("fruzzy: unable to write to file: ", e)
        print("fruzzy: saving as %s" % altfile)
        urllib.request.urlretrieve(asset['browser_download_url'], altfile)
        print("fruzzy: Exit vim/nvim & rename %s file to %s " %
              (altfile, outfile))


if __name__ == "__main__":
    install()

