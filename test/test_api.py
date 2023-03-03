import threading
import pytest
import quickmq
from quickmq.api import _CURRENT_SESSION
import json


@pytest.fixture(autouse=True)
def start_easymq():
    quickmq.connect('localhost')
    yield
    quickmq.disconnect()


def test_connection():
    quickmq.connect('localhost')
    assert len(_CURRENT_SESSION.pool.connections) == 1
    quickmq.disconnect()
    assert len(_CURRENT_SESSION.pool.connections) == 0


@pytest.mark.parametrize('exchange', ['amq.fanout'])
def test_publish(create_listener):
    msg = "Hello World!"
    quickmq.publish(message=msg, exchange='amq.fanout', confirm_delivery=True)
    rcvd_bytes = create_listener.get_message(block=True)
    assert json.loads(rcvd_bytes) == msg


def test_consume():
    def _clbk():
        pass
    with pytest.raises(NotImplementedError):
        quickmq.consume(_clbk)


def test_get():
    with pytest.raises(NotImplementedError):
        quickmq.get()


@pytest.mark.parametrize('exchange', ['amq.fanout'])
def test_publish_all(create_listener):
    msgs = ["Hello", "World!"]
    quickmq.publish_all(msgs, exchange='amq.fanout', confirm_delivery=True)
    for msg in msgs:
        assert json.loads(create_listener.get_message(block=True)) == msg


def test_publish_non_exchange():
    with pytest.raises(Exception):
        quickmq.publish('Test', exchange='not_existent_exchange', confirm_delivery=True)
    quickmq.publish('test', exchange='not_existent_exchange')


@pytest.mark.parametrize('exchange', ['amq.fanout'])
def test_mulithreading(create_listener):
    msg = "Hello World!"
    quickmq.connect('localhost')
    t = threading.Thread(target=quickmq.publish, args=(msg,), kwargs={'exchange': 'amq.fanout', 'confirm_delivery': True})
    t.start()
    t.join()
    rcvd_bytes = create_listener.get_message(block=True)
    assert json.loads(rcvd_bytes) == msg
