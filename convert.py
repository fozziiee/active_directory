with open("./capitals.txt", "r") as f:
    names = [name.strip().lower() for name in f.readlines()]

with open("./last-names.txt", "w") as f:
    f.write("\n".join(names))