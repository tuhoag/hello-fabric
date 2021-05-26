import os
import flask
from flask import request, jsonify

app = flask.Flask(__name__)
app.config["DEBUG"] = True

@app.route('/helloworld', methods=['GET'])
def helloworld():
    return "hello world"


@app.route('/hello', methods=['GET'])
def hello():
    if 'name' in request.args:
        name = request.args['name']
    else:
        return "Error: No name provided."

    return "hello {name}".format(name=name)

if __name__ == "__main__":
    print("Start listening in port: {port}".format(port=os.environ["API_PORT"]))
    app.run(host='0.0.0.0', port=os.environ["API_PORT"])