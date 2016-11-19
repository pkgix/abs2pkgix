
def prefix_ize(pkg_name, line):
    if pkg_name == "boost":
        if "python" in line: return False
    return True

